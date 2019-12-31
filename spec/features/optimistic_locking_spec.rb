# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Optimistic Locking" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    sign_in user
  end

  context "Editing a Raster Resource that has been updated by another process" do
    let(:resource) { FactoryBot.create_for_repository(:raster_resource) }
    it "presents an error" do
      visit edit_raster_resource_path(resource)
      test_optlock(resource)
    end
  end

  context "Editing a Scanned Resource that has been updated by another process" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
    it "presents an error" do
      visit edit_scanned_resource_path(resource)
      test_optlock(resource)
    end
  end

  def test_optlock(resource)
    # update the resource out of band
    change_set_persister.save(change_set: DynamicChangeSet.new(resource))

    # update from UI
    click_button "Save"

    expect(page).to have_content "Sorry, another user or process updated this resource simultaneously."
    # rendering edit from the update action results in a url path without
    # `/edit` on the end. But it should have the form.
    expect(page).to have_button "Save"
  end
end
