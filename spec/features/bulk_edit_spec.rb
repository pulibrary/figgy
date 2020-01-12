# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Bulk edit", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:collection_title) { "My Collection" }
  let(:collection) { FactoryBot.create_for_repository(:collection, title: collection_title) }
  let(:member_scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource, title: ["Member Resource"], member_of_collection_ids: [collection.id])
  end
  let(:nonmember_scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource, title: ["Nonmember Resource"])
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    [collection, member_scanned_resource, nonmember_scanned_resource].each do |resource|
      change_set = DynamicChangeSet.new(resource)
      change_set_persister.save(change_set: change_set)
    end
    sign_in user
  end

  context "the bulk edit button" do
    it "will not display in an empty search" do
      visit root_path(q: "")

      expect(page).not_to have_css("#bulk-edit")
      expect(page).to have_content("My Collection")
      expect(page).to have_content("Member Resource")
      expect(page).to have_content("Nonmember Resource")
    end

    it "will display when a collection is selected" do
      visit root_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")

      expect(page).to have_content("Member Resource")
      expect(page).not_to have_content("Nonmember Resource")
      expect(page).to have_css("#bulk-edit")
      # We can't test the whole href because it is constructed
      #   from path not as an absolute url
      link = page.find_link("Bulk Edit")
      uri = URI(link["href"])
      expect(uri.query).to eq "f%5Bmember_of_collection_titles_ssim%5D%5B%5D=My+Collection&q="
      expect(uri.path).to eq "/bulk_edit"
    end
  end

  context "submit form" do
    with_queue_adapter :inline
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "4609321")
    end
    it "updates the object" do
      visit bulk_edit_resources_edit_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")
      expect(page).to have_content "You searched for"
      page.driver.execute_script("document.getElementById('mark_complete').click()")
      accept_alert do
        page.driver.execute_script("document.getElementById('bulk-edit-submit').click()")
      end
      expect(current_path).to eq root_path
      expect(page).to have_content "1 resources were queued for bulk update."
      expect(adapter.query_service.find_by(id: member_scanned_resource.id).state).to eq ["complete"]
    end
  end
end
