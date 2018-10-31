# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe FileSetsController do
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:user) { FactoryBot.create(:admin) }
  let(:manifest_helper_class) { class_double(ManifestBuilder::ManifestHelper).as_stubbed_const(transfer_nested_constants: true) }
  let(:manifest_helper) { instance_double(ManifestBuilder::ManifestHelper) }
  let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
  before do
    sign_in user if user
    allow(manifest_helper).to receive(:polymorphic_url).and_return("http://test")
    allow(manifest_helper_class).to receive(:new).and_return(manifest_helper)
    allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
  end
  describe "PATCH /file_sets/id" do
    it "can update a file set" do
      file_set = FactoryBot.create_for_repository(:file_set)
      patch :update, params: { id: file_set.id.to_s, file_set: { title: ["Second"] } }

      file_set = query_service.find_by(id: file_set.id)
      expect(file_set.title).to eq ["Second"]
    end

    context "with an invalid FileSet ID" do
      it "displays an error" do
        expect { patch :update, params: { id: "no-exist", file_set: { title: ["Second"] } } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end

    context "with replacement master and derivative files" do
      with_queue_adapter :inline
      let(:master_file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:derivative_file) { fixture_file_upload("files/example.jp2", "image/jp2") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, title: "Test Title", files: [master_file]) }
      let(:file_set) { Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.member_ids.first) }

      it "uploads master and derivative files to separate locations" do
        updated_master_file = fixture_file_upload("files/example.tif", "image/tiff")
        updated_derivative_file = fixture_file_upload("files/example.jp2", "image/jp2")

        patch :update, params: {
          id: file_set.id.to_s,
          file_set: {
            files: [
              { file_set.file_metadata.first.id => updated_master_file }
            ],
            derivative_files: [
              { file_set.file_metadata.last.id => updated_derivative_file }
            ]
          }
        }

        updated_file_set = query_service.find_by(id: file_set.id)
        expect(updated_file_set.file_metadata.length).to eq 2
        expect(updated_file_set.file_metadata.first).to be_a FileMetadata
        expect(updated_file_set.file_metadata.last).to be_a FileMetadata
      end
    end
  end

  describe "GET /concern/file_sets/:id/edit" do
    render_views
    it "renders" do
      file_set = FactoryBot.create_for_repository(:file_set)

      expect { get :edit, params: { id: file_set.id.to_s } }.not_to raise_error
    end
  end

  describe "GET /concern/file_sets/:id/text" do
    render_views
    it "renders the ocr_content property as text" do
      file_set = FactoryBot.create_for_repository(:file_set, ocr_content: "blabla test")
      get :text, params: { id: file_set.id.to_s }
      expect(response.body).to eq "blabla test"
      expect(response.content_type).to eq "text/plain"
    end
  end

  describe "GET /concern/file_sets/:id/manifest", run_real_derivatives: true do
    with_queue_adapter :inline
    # get around the stubbing in earlier test setup; we need to test actual manifest behavior
    let(:manifest_helper_class) { ManifestBuilder::ManifestHelper }
    let(:file) do
      fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "audio/x-wav")
    end
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
    let(:scanned_resource) do
      sr = ScannedResource.new(title: "Test Title", rights_statement: "http://rightsstatements.org/vocab/CNE/1.0/", visibility: "public")
      cs = ScannedResourceChangeSet.new(sr, files: [file])
      change_set_persister.save(change_set: cs)
    end
    let(:file_set) { scanned_resource.decorate.members.first }

    before do
      allow(manifest_helper_class).to receive(:new).and_call_original
      scanned_resource
    end

    render_views
    it "renders the manifest as json" do
      get :manifest, params: { id: file_set.id.to_s }, format: :json

      expect(response.content_type).to eq "application/json"
      manifest_values = JSON.parse(response.body)

      expect(manifest_values["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
      expect(manifest_values["rendering"]).not_to be_empty
      expect(manifest_values["rendering"].first).to include("id" => "http://www.example.com/downloads/#{file_set.id}/file/#{file_set.derivative_files.first.id}")
      expect(manifest_values["rendering"].first).to include("label" => { "en" => ["Download as MP3"] })
      expect(manifest_values["rendering"].first).to include("format" => "audio/mp3")
    end
    context "when an invalid FileSet ID is requested" do
      before do
        allow(Valkyrie.logger).to receive(:error)
      end
      it "raises an error" do
        get :manifest, params: { id: "invalid" }, format: :json
        expect(response.status).to eq(404)
        expect(Valkyrie.logger).to have_received(:error).with("FileSetsController: Failed to load the FileSet for the ID invalid")

        expect(response.content_type).to eq "application/json"
        manifest_values = JSON.parse(response.body)
        expect(manifest_values).to include("message" => "No manifest found for invalid")
      end
    end
  end

  describe "PUT /file_sets/id" do
    context "with a derivative service for images in the TIFF" do
      let(:create_derivatives_class) { class_double(RegenerateDerivativesJob).as_stubbed_const(transfer_nested_constants: true) }
      let(:original_file) { instance_double(FileMetadata) }
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      before do
        allow(original_file).to receive(:mime_type).and_return("image/tiff")
        allow(file_set).to receive(:original_file).and_return(original_file)
        allow(create_derivatives_class).to receive(:perform_later).and_return(success: true)
      end

      it "can regenerate derivatives" do
        put :derivatives, params: { id: file_set.id.to_s }

        expect(response).to redirect_to(file_set)
        expect(create_derivatives_class).to have_received(:perform_later)
      end

      it "can return json" do
        put :derivatives, params: { id: file_set.id.to_s }, format: :json

        expect(response.status).to eq 200
        expect(response.body).to eq "{\"success\":true}"
      end
    end
  end

  describe "DELETE /concern/file_sets/id" do
    render_views
    it "deletes a file set" do
      file_set = FactoryBot.create_for_repository(:file_set)
      FactoryBot.create_for_repository(:scanned_resource, member_ids: [file_set.id])

      expect { delete :destroy, params: { id: file_set.id.to_s } }.not_to raise_error
    end
  end
end
