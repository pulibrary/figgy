# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkIngestController do
  describe "GET #show" do
    let(:user) { FactoryBot.create(:admin) }

    context "when logged in" do
      before do
        sign_in user if user
      end

      it "assigns workflow states based on the resource type" do
        get :show, params: { resource_type: "scanned_maps" }
        expect(assigns(:states)).to eq ["pending", "final_review", "complete", "takedown", "flagged"]
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
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the directory as a single resource" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", workflow: { state: "pending" }, visibility: "open", mvw: false, selected_files: selected_files }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: "/base/resource1", state: "pending", visibility: "open"))
      end
    end

    context "with two single-volume resources" do
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "1" => { "url" => "/base/resource2/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", workflow: { state: "pending" }, visibility: "open", mvw: false, selected_files: selected_files }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open"))
      end
    end

    context "with one multi-volume resource" do
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/vol1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "1" => { "url" => "/base/resource1/vol2/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", workflow: { state: "pending" }, visibility: "open", mvw: true, selected_files: selected_files }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open"))
      end
    end

    context "with two multi-volume resources" do
      let(:selected_files) do
        {
          "0" => { "url" => "/base/resource1/vol1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "1" => { "url" => "/base/resource1/vol2/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "2" => { "url" => "/base/resource2/vol1/1.tif", "file_name" => "1.tif", "file_size" => "100" },
          "3" => { "url" => "/base/resource2/vol2/1.tif", "file_name" => "1.tif", "file_size" => "100" }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", workflow: { state: "pending" }, visibility: "open", mvw: true, selected_files: selected_files }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open"))
      end
    end
  end
end
