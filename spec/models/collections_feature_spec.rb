# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Refresh" do
  let(:user) { FactoryBot.create(:admin) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  let(:collection) { persister.save(resource: FactoryBot.build(:collection)) }
  before do
    sign_in user
    persister.save(resource: FactoryBot.build(:scanned_resource, member_of_collection_ids: [collection.id]))
  end

  context "collection with members" do
    it "selects the sort_by field and sort members" do
      visit "catalog/#{collection.id}"
      expect(page).to have_link "View all 1 items in this collection"
      expect(page).to have_link "Edit This Collection", href: edit_collection_path(collection)
      expect(page).to have_link "Delete This Collection", href: collection_path(collection)
      expect(page).not_to have_link "File Manager"
    end
  end

  context "editing collections" do
    it "allows selecting multiple owners" do
      visit "collections/#{collection.id}/edit"
      expect(page).to have_xpath "//select[@multiple='multiple' and @name='collection[owners][]']"
    end
  end
end
