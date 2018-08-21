# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Refresh", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  before do
    sign_in user
  end

  context "archival media collection with members" do
    it "selects the sort_by field and sort members", js: true do
      collection = persister.save(resource: FactoryBot.build(:archival_media_collection))
      persister.save(resource: FactoryBot.build(:complete_media_resource, member_of_collection_ids: [collection.id]))
      visit "catalog/#{collection.id}"
      expect(page).to have_link "View Members List"
      expect(page).to have_link "View ARK / Component ID report"
      expect(page).to have_link "Edit This Archival Media Collection", href: edit_archival_media_collection_path(collection)
      expect(page).to have_link "Delete This Archival Media Collection", href: archival_media_collection_path(collection)
      expect(page).not_to have_link "File Manager"
    end
  end
end
