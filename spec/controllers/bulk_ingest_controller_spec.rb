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

    context "when a directory has no sub-directories" do
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:selected_files) do
        {
          "0" => { "url" => "#{single_dir}/color.tif", "file_name" => "color.tif", "file_size" => "100" },
          "1" => { "url" => "#{single_dir}/gray.tif", "file_name" => "gray.tif", "file_size" => "100" }
        }
      end

      it "ingests the directory as a single resource" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", workflow: { state: "pending" }, visibility: "open", selected_files: selected_files }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: single_dir.to_s, state: "pending", visibility: "open"))
      end
    end

    context "when a directory has sub-directories" do
      let(:multi_dir) { Rails.root.join("spec", "fixtures", "ingest_multi") }
      let(:selected_files) do
        {
          "0" => { "url" => "#{multi_dir}/vol1/color.tif", "file_name" => "color.tif", "file_size" => "100" },
          "1" => { "url" => "#{multi_dir}/vol2/gray.tif", "file_name" => "gray.tif", "file_size" => "100" }
        }
      end

      it "ingests the directory as multiple resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", workflow: { state: "complete" }, visibility: "private", selected_files: selected_files }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: multi_dir.to_s, state: "complete", visibility: "private"))
      end
    end
  end
end
