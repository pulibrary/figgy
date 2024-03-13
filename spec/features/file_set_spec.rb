# frozen_string_literal: true
require "rails_helper"

RSpec.feature "FileSet" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid
    sign_in user
  end

  scenario "file set show page has a health status" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first

    visit solr_document_path(id: file_set.id)
    expect(page).to have_selector("#health-status")
    expect(page).not_to have_link "Attach Caption"
  end

  scenario "with a cloud fixity failure, file set show page has a needs attention health status" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, state: "complete", files: [file])
    file_set = Wayfinder.for(resource).file_sets.first
    po = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id)
    FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource.id)
    FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: po.id, status: "FAILURE", current: true)

    visit solr_document_path(id: file_set.id)
    expect(page).to have_selector("#health-status")
    expect(page).to have_text("Health Status: Needs Attention")
    expect(page).to have_text("Cloud Fixity Status: Needs Attention")
  end

  scenario "fileset fixity ui table shows the Last Success if it's a preserved file" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first

    visit solr_document_path(id: file_set.id)
    expect(page).to have_css ".preserved", text: "Last Success:"
  end

  context "when there is a derivative file" do
    with_queue_adapter :inline
    scenario "the fileset fixity ui table informs the user of any files that are intentionally not preserved" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
      file_set = Wayfinder.for(resource).file_sets.first
      change_set_persister = ChangeSetPersister.default
      query_service = change_set_persister.query_service
      reloaded_resource = query_service.find_by(id: resource.id)
      persisted_resource = change_set_persister.metadata_adapter.persister.save(resource: reloaded_resource)
      change_set = ChangeSet.for(persisted_resource)
      change_set_persister.save(change_set: change_set)

      visit solr_document_path(id: file_set.id)
      expect(page).to have_css ".not_preserved", text: "Derivative files are not preserved."
    end
  end

  context "when creating a caption" do
    with_queue_adapter :inline
    it "can attach and delete a caption via a form" do
      resource = FactoryBot.create_for_repository(:scanned_resource_with_video)
      file_set = Wayfinder.for(resource).file_sets.first

      visit solr_document_path(id: file_set.id)
      click_link "Attach Caption"

      attach_file(Rails.root.join("spec", "fixtures", "files", "caption.vtt"))
      select "English", from: "file_metadata[caption_language]"
      check "Is this caption in the original language of the audio?"
      click_button "Save"

      expect(page).to have_content file_set.title.first
      caption = Wayfinder.for(resource).file_sets.first.captions.first
      expect(caption.caption_language).to eq "eng"
      expect(caption.file_identifiers.length).to eq 1
      expect(caption.original_language_caption).to eq true
      expect(page).to have_content "caption.vtt"
      expect(page).to have_css(".badge-dark", text: "Caption")
      expect(page).to have_css(".badge-dark", text: "English (Original)")
      within(".files") do
        click_link "Delete"
      end
      expect(page).not_to have_content "caption.vtt"
    end
  end

  context "in the edit form" do
    with_queue_adapter :inline
    it "can mark a video fileset as not requiring captions", js: true do
      resource = FactoryBot.create_for_repository(:scanned_resource_with_video)
      file_set = Wayfinder.for(resource).file_sets.first
      expect(file_set.captions_required).to be true

      visit edit_file_set_path(id: file_set.id)

      expect(find_field("file_set_captions_required_yes")).to be_checked

      expect(page).not_to have_content "Princeton University Library has a legal obligation"
      click_link("caption-requirement-info")
      expect(page).to have_content "Princeton University Library has a legal obligation"
      click_button("close-caption-requirement-modal")

      choose("file_set_captions_required_no")
      click_button "Save"

      file_set = ChangeSetPersister.default.query_service.find_by(id: file_set.id)
      expect(file_set.captions_required).to be false
    end

    it "does not ask if captions are required for an image fileset" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
      file_set = Wayfinder.for(resource).file_sets.first
      expect(file_set.captions_required).to be_nil

      visit edit_file_set_path(id: file_set.id)

      expect(page).not_to have_field "file_set_captions_required_yes"
    end
  end
end
