# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Letter" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:letter) do
    res = FactoryBot.create_for_repository(:letter)
    persister.save(resource: res)
  end
  let(:change_set) do
    LetterChangeSet.new(letter)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  scenario "creating a new resource" do
    visit new_letter_scanned_resources_path

    expect(page).to have_css '.select[for="scanned_resource_rights_statement"]', text: "Rights Statement"
    expect(page).to have_css '.select[for="scanned_resource_member_of_collection_ids"]', text: "Collections"
    expect(page).to have_field "Title"
    expect(page).to have_field "Sender Name"
    expect(page).to have_field "Sender Place"
    expect(page).to have_field "Recipient Name"
    expect(page).to have_field "Recipient Place"

    fill_in "Title", with: "a letter"
    click_button "Save"

    expect(page).to have_content "a letter"
  end

  context "when a user creates a new numismatic issue" do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:sender1) { NameWithPlace.new(name: "Sender Name 1", place: "Sender Place 1") }
    let(:sender2) { NameWithPlace.new(name: "Sender Name 2", place: "Sender Place 2") }
    let(:letter) do
      FactoryBot.create_for_repository(
        :letter,
        title: "a letter",
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        member_of_collection_ids: [collection.id],
        sender: [sender1, sender2]
      )
    end

    scenario "viewing a resource" do
      visit solr_document_path letter

      expect(page).to have_css ".attribute.rendered_rights_statement", text: "Copyright Not Evaluated"
      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.member_of_collections", text: "Title"
      expect(page).to have_css ".attribute.title", text: "a letter"
      expect(page).to have_css ".attribute.rendered_sender", text: "Sender Name 1; Sender Place 1"
      expect(page).to have_css ".attribute.rendered_sender", text: "Sender Name 2; Sender Place 2"
    end

    scenario "user can edit a letter to update sender and recipient", js: true do
      visit edit_scanned_resource_path letter

      within "#sender" do
        find(".remove_fields", match: :first).click
      end

      fill_in "Recipient Name", with: "Recipient Name 1"
      fill_in "Recipient Place", with: "Recipient Place 1"

      click_button "Save"

      visit solr_document_path letter

      expect(page).not_to have_css ".attribute.rendered_sender", text: "Sender Name 1; Sender Place 1"
      expect(page).to have_css ".attribute.rendered_sender", text: "Sender Name 2; Sender Place 2"
      expect(page).to have_css ".attribute.rendered_recipient", text: "Recipient Name 1; Recipient Place 1"
    end
  end
end
