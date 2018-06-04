# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkIngestController do
  describe "GET #show" do
    let(:user) { FactoryBot.create(:admin) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:persister) { adapter.persister }

    context "when logged in" do
      before do
        sign_in user if user
      end

      it "assigns workflow states based on the resource type" do
        get :show, params: { resource_type: "scanned_maps" }
        expect(assigns(:states)).to eq ["pending", "final_review", "complete", "takedown", "flagged"]
      end

      it "assigns collections" do
        collection = persister.save(resource: FactoryBot.build(:collection))
        get :show, params: { resource_type: "scanned_maps" }
        expect(assigns(:collections)).to eq [[collection.title.first, collection.id.to_s]]
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get :show, params: { resource_type: "scanned_maps" }
        expect(response).to redirect_to("/users/auth/cas")
      end
    end
  end

  describe "POST #browse_everything_files" do
    before do
      allow(IngestFolderJob).to receive(:perform_later)
      allow(IngestFoldersJob).to receive(:perform_later)
    end

    context "with one single-volume resource" do
      let(:attributes) do
        {
          workflow: { state: "pending" },
          collections: ["1234567"],
          visibility: "open",
          mvw: false,
          selected_files: selected_files
        }
      end
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the directory as a single resource" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: "/base/resource1", state: "pending", visibility: "open", member_of_collection_ids: ["1234567"]))
      end
    end

    context "with two single-volume resources" do
      let(:attributes) do
        {
          workflow: { state: "pending" },
          collections: ["1234567"],
          visibility: "open",
          mvw: false,
          selected_files: selected_files
        }
      end
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "1" => { "url" => "/base/resource2/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open", member_of_collection_ids: ["1234567"]))
      end
    end

    context "with one multi-volume resource" do
      let(:attributes) do
        {
          workflow: { state: "pending" },
          collections: ["1234567"],
          visibility: "open",
          mvw: true,
          selected_files: selected_files
        }
      end
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/vol1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "1" => { "url" => "/base/resource1/vol2/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open", member_of_collection_ids: ["1234567"]))
      end
    end

    context "with two multi-volume resources" do
      let(:attributes) do
        {
          workflow: { state: "pending" },
          collections: ["1234567"],
          visibility: "open",
          mvw: true,
          selected_files: selected_files
        }
      end
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/vol1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "1" => { "url" => "/base/resource1/vol2/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "2" => { "url" => "/base/resource2/vol1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "3" => { "url" => "/base/resource2/vol2/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open", member_of_collection_ids: ["1234567"]))
      end
    end
  end
end
