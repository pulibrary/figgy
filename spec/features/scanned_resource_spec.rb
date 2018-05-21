# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Scanned Resources", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:scanned_resource) do
    res = FactoryBot.create_for_repository(:scanned_resource)
    adapter.persister.save(resource: res)
  end
  let(:change_set) do
    ScannedResourceChangeSet.new(scanned_resource)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    change_set.source_metadata_identifier = "4612596"
    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  context "when a user creates a new scanned resource" do
    context "with scanned resources already created" do
      scenario "users see a warning if they try to use duplicate barcodes" do
        visit new_scanned_resource_path
        page.fill_in "scanned_resource_source_metadata_identifier", with: "4612596"
        find("#scanned_resource_portion_note").click
        expect(page).to have_content "This ID is already in use"

        page.fill_in "scanned_resource_source_metadata_identifier", with: "8543429"
        page.fill_in "scanned_resource_portion_note", with: "Test another note"
        expect(page).not_to have_content "This ID is already in use"
      end
    end
  end

  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  let(:volume1) do
    persister.save(resource: FactoryBot.create_for_repository(:scanned_resource, title: "vol1"))
  end
  let(:multi_volume_work) do
    persister.save(resource: FactoryBot.create_for_repository(:scanned_resource, member_ids: [volume1.id]))
  end

  context "within a multi-volume work" do
    before do
      multi_volume_work
    end

    scenario "the volumes are displayed as members" do
      visit solr_document_path(multi_volume_work)

      expect(page).to have_selector "h2", text: "Members"
      expect(page).to have_selector "td", text: "vol1"
    end
  end

  context "as a staff user" do
    let(:user) { FactoryBot.create(:staff) }

    it "shows the admin controls" do
      visit solr_document_path(scanned_resource)
      expect(page).to have_link "File Manager", href: file_manager_scanned_resource_path(scanned_resource)
    end
  end
end
