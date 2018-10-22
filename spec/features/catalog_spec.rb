# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Scanned Resources" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource, title: ["New test work"], local_identifier: ["TEST123"])
  end
  let(:change_set) do
    ScannedResourceChangeSet.new(scanned_resource)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  context "when a user creates a new scanned resource" do
    scenario "users can perform case-insensitive searches for local identifiers" do
      visit root_path
      fill_in id: "catalog_search", with: "test123"
      click_button id: "keyword-search-submit"
      expect(page).to have_content "New test work"
    end
  end
end
