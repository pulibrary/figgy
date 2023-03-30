# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Browsing archival media collections" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:collection) do
    resource = FactoryBot.build(:collection, change_set: "archival_media_collection")
    change_set = ChangeSet.for(resource, source_metadata_identifier: "C0652")
    change_set_persister.save(change_set: change_set)
  end
  let(:file) { fixture_file_upload("files/audio_file.wav") }
  let(:member) do
    resource = FactoryBot.build(:complete_recording)
    change_set = RecordingChangeSet.new(resource, member_of_collection_ids: [collection.id], files: [file])
    change_set_persister.save(change_set: change_set)
  end

  before do
    stub_findingaid(pulfa_id: "C0652")
    stub_findingaid(pulfa_id: "C0652_c0377")
    stub_ezid(shoulder: "99999/fk4", blade: "123456")
    member
    sign_in user
  end

  context "when an archival media collection has members" do
    it "links to the members" do
      visit "catalog/#{collection.id}"

      expect(page).to have_link "View all 1 items in this collection"
      expect(page).to have_link "View ARK report"
      expect(page).to have_link "Edit This Archival Media Collection", href: edit_collection_path(collection)
      expect(page).to have_link "Delete This Archival Media Collection", href: collection_path(collection)
    end
  end

  context "when ingesting a new archival media collection", js: true do
    it "provides a file browser for selecting bag paths" do
      visit "collections/new/archival_media_collection"

      expect(page).to have_css ".btn-bag-path.browse-everything"
      click_on(class: "btn-bag-path")
      expect(page).to have_css "#file-browser-container"
    end
  end
end
