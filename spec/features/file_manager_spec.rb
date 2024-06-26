# frozen_string_literal: true
require "rails_helper"

RSpec.feature "File Manager" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:resource) do
    res = FactoryBot.create_for_repository(:scanned_resource)
    res.member_ids = [file_set.id]
    adapter.persister.save(resource: res)
  end

  before do
    stub_ezid
    sign_in user
  end

  context "without a derivative file" do
    let(:riiif_helper) { instance_double(ManifestBuilder::RiiifHelper) }
    let(:riiif_helper_class) { class_double(ManifestBuilder::RiiifHelper).as_stubbed_const(transfer_nested_constants: true) }
    before do
      allow(riiif_helper).to receive(:base_url).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      allow(riiif_helper_class).to receive(:new).and_return(riiif_helper)
    end
    scenario "users visit the file management interface" do
      visit polymorphic_path [:file_manager, resource]

      expect(page).not_to have_selector(".thumbnail span.ignore-select")
    end
  end

  context "when a file is preserved" do
    with_queue_adapter :inline
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:resource) do
      FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
    end
    before do
      # Prevent deleting files.
      allow(CleanupFilesJob).to receive(:perform_later).and_return(true)
    end
    it "can be deleted and reinstated" do
      visit polymorphic_path [:file_manager, resource]

      click_link "Edit"
      click_link "Delete This File Set"
      click_link "File Manager"
      expect(page).not_to have_link "Edit"
      click_button "Reinstate"
      click_link "File Manager"

      expect(page).to have_link "Edit"
    end
  end

  context "with a derivative file" do
    let(:riiif_helper) { instance_double(ManifestBuilder::RiiifHelper) }
    let(:riiif_helper_class) { class_double(ManifestBuilder::RiiifHelper).as_stubbed_const(transfer_nested_constants: true) }
    before do
      allow(riiif_helper).to receive(:base_url).and_return("http://localhost/test-resource")
      allow(riiif_helper_class).to receive(:new).and_return(riiif_helper)
    end
    context "with a derivative service for images in the TIFF" do
      let(:create_derivatives_class) { class_double(CreateDerivativesJob).as_stubbed_const(transfer_nested_constants: true) }
      let(:original_file) { instance_double(FileMetadata) }
      before do
        allow(original_file).to receive(:mime_type).and_return("image/tiff")
        allow(file_set).to receive(:original_file).and_return(original_file)
        allow(create_derivatives_class).to receive(:perform_later).and_return(success: true)
      end
      xscenario "users regenerate derivatives for a file set" do
        visit polymorphic_path [:file_manager, resource]

        expect(page).to have_selector("form.rederive button")
        click_button "Regenerate Derivatives"
        expect(page).to have_selector ".alert-success .text", text: "Derivatives are being regenerated"
      end
      context "when the derivative service fails" do
        before do
          allow(create_derivatives_class).to receive(:perform_later).and_raise(Hydra::Derivatives::TimeoutError)
        end
        xscenario "users cannot regenerate derivatives for a file set" do
          visit polymorphic_path [:file_manager, resource]

          expect(page).to have_selector("form.rederive button")
          click_button "Regenerate Derivatives"
          expect(page).to have_selector ".alert-danger .text", text: "Derivatives cannot be regenerated"
        end
      end
    end
  end

  context "with a geo metadata file that has an error" do
    let(:original_file) { FileMetadata.new(use: ::PcdmUse::OriginalFile, mime_type: "application/xml; schema=fgdc", error_message: ["errors"]) }
    let(:extractor) { instance_double(GeoMetadataExtractor) }
    let(:resource) do
      res = FactoryBot.create_for_repository(:scanned_map)
      res.member_ids = [file_set.id]
      adapter.persister.save(resource: res)
    end

    before do
      file_set.file_metadata = [original_file]
      adapter.persister.save(resource: file_set)
      allow(GeoMetadataExtractor).to receive(:new).and_return(extractor)
      allow(extractor).to receive(:extract).and_return(true)
    end

    scenario "users are notified of the failure", js: true do
      visit polymorphic_path [:file_manager, resource]
      expect(page).to have_content("Metadata Extraction Failed")
    end
  end

  context "with a child resource" do
    let(:child_resource) { FactoryBot.create_for_repository(:scanned_resource, title: "Child Resource") }
    let(:resource) do
      res = FactoryBot.create_for_repository(:scanned_resource)
      res.member_ids = [file_set.id, child_resource.id]
      adapter.persister.save(resource: res)
    end

    it "doesn't render the child" do
      visit polymorphic_path [:file_manager, resource]
      expect(page).to have_selector("form[data-type='json']", count: 1)
      expect(page).not_to have_selector("form[data-type='json']", text: "Child Resource")
    end

    it "uses cached parents for thumbnails" do
      resource
      allow(adapter.query_service).to receive(:find_inverse_references_by).and_call_original

      visit polymorphic_path [:file_manager, resource]

      expect(adapter.query_service).to have_received(:find_inverse_references_by).exactly(2).times
    end
  end
end
