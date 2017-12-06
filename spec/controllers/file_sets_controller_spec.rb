# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe FileSetsController do
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:user) { FactoryGirl.create(:admin) }
  let(:manifest_helper_class) { class_double(ManifestBuilder::ManifestHelper).as_stubbed_const(transfer_nested_constants: true) }
  let(:manifest_helper) { instance_double(ManifestBuilder::ManifestHelper) }
  let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
  before do
    sign_in user if user
    allow(manifest_helper).to receive(:polymorphic_url).and_return('http://test')
    allow(manifest_helper_class).to receive(:new).and_return(manifest_helper)
    allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
  end
  describe "PATCH /file_sets/id" do
    it "can update a file set" do
      file_set = FactoryGirl.create_for_repository(:file_set)
      patch :update, params: { id: file_set.id.to_s, file_set: { title: ["Second"] } }

      file_set = query_service.find_by(id: file_set.id)
      expect(file_set.title).to eq ["Second"]
    end

    context 'with replacement master and derivative files' do
      let(:master_file) { fixture_file_upload('files/example.tif', 'image/tiff') }
      let(:derivative_file) { fixture_file_upload('files/example.jp2', 'image/jp2') }
      let(:scanned_resource) { FactoryGirl.create_for_repository(:scanned_resource, title: "Test Title", files: [master_file]) }
      let(:file_set) { Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.member_ids.first) }

      it 'uploads master and derivative files to separate locations' do
        updated_master_file = fixture_file_upload('files/example.tif', 'image/tiff')
        updated_derivative_file = fixture_file_upload('files/example.jp2', 'image/jp2')

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
      file_set = FactoryGirl.create_for_repository(:file_set)

      expect { get :edit, params: { id: file_set.id.to_s } }.not_to raise_error
    end
  end

  describe "PUT /file_sets/id" do
    context 'with a derivative service for images in the TIFF' do
      let(:create_derivatives_class) { class_double(CreateDerivativesJob).as_stubbed_const(transfer_nested_constants: true) }
      let(:original_file) { instance_double(FileMetadata) }
      let(:file_set) { FactoryGirl.create_for_repository(:file_set) }
      before do
        allow(original_file).to receive(:mime_type).and_return('image/tiff')
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
      file_set = FactoryGirl.create_for_repository(:file_set)
      FactoryGirl.create_for_repository(:scanned_resource, member_ids: [file_set.id])

      expect { delete :destroy, params: { id: file_set.id.to_s } }.not_to raise_error
    end
  end
end
