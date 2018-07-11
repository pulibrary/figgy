# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Refresh", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  before do
    sign_in user
  end

  context "collection with members" do
    it "selects the sort_by field and sort members", js: true do
      collection = persister.save(resource: FactoryBot.build(:collection))
      persister.save(resource: FactoryBot.build(:scanned_resource, member_of_collection_ids: [collection.id]))

      visit "catalog/#{collection.id}"
      expect(page).to have_link "View Members List"
      expect(page).to have_link "Edit This Collection", href: edit_collection_path(collection)
      expect(page).to have_link "Delete This Collection", href: collection_path(collection)
      expect(page).not_to have_link "File Manager"
    end
  end
end
