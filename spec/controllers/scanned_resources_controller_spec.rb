# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe ScannedResourcesController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  before do
    sign_in user if user
  end
  context "when an admin" do
    let(:user) { FactoryGirl.create(:admin) }
    describe "GET /scanned_resources/:id/file_manager" do
      it "sets the record and children variables" do
        child = FactoryGirl.create_for_repository(:file_set)
        parent = FactoryGirl.create_for_repository(:scanned_resource, member_ids: child.id)

        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end

    describe "POST /concern/scanned_resources/:id/browse_everything_files" do
      let(:file) { File.open(Rails.root.join("spec", "fixtures", "files", "example.tif")) }
      let(:params) do
        {
          "selected_files" => {
            "0" => {
              "url" => "file://#{file.path}",
              "file_name" => File.basename(file.path),
              "file_size" => file.size
            }
          }
        }
      end
      it "uploads files" do
        resource = FactoryGirl.create_for_repository(:scanned_resource)
        # Ensure that indexing is always safe and done at the end.
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(Valkyrie::MetadataAdapter.find(:index_solr).persister)
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save).and_call_original

        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
        reloaded = adapter.query_service.find_by(id: resource.id)

        expect(reloaded.member_ids.length).to eq 1
        expect(reloaded.pending_uploads).to be_empty
        expect(Valkyrie::MetadataAdapter.find(:index_solr).persister).not_to have_received(:save)

        file_sets = Valkyrie.config.metadata_adapter.query_service.find_members(resource: reloaded)
        expect(file_sets.first.member_ids.length).to eq 2
      end
      it "tracks pending uploads" do
        resource = FactoryGirl.create_for_repository(:scanned_resource)
        allow(BrowseEverythingIngestJob).to receive(:perform_later).and_return(true)

        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
        reloaded = adapter.query_service.find_by(id: resource.id)

        pending_upload = reloaded.pending_uploads[0]
        expect(pending_upload.file_name).to eq [File.basename(file.path)]
        expect(pending_upload.url).to eq ["file://#{file.path}"]
        expect(pending_upload.file_size).to eq [file.size]
        expect(pending_upload.created_at).not_to be_blank
      end
    end
  end

  describe "GET /concern/scanned_resources/:id/manifest" do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    it "returns a IIIF manifest for a resource with a file" do
      scanned_resource = FactoryGirl.create_for_repository(:scanned_resource, files: [file])

      get :manifest, params: { id: scanned_resource.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
    end
  end
end
