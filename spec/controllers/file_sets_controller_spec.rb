# frozen_string_literal: true
require 'rails_helper'

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
