# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkIngestController do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

  describe ".metadata_adapter" do
    it "returns an adapter" do
      expect(described_class.metadata_adapter).to be_an IndexingAdapter
    end
  end

  describe ".storage_adapter" do
    it "returns an adapter" do
      expect(described_class.storage_adapter).to be_an InstrumentedStorageAdapter
    end
  end

  describe ".change_set_persister" do
    it "accesses the ChangeSetPersister" do
      expect(described_class.change_set_persister).to be_a ChangeSetPersister::Basic
      expect(described_class.change_set_persister.metadata_adapter).to be described_class.metadata_adapter
      expect(described_class.change_set_persister.storage_adapter).to be described_class.storage_adapter
    end
  end

  describe "GET #show" do
    let(:user) { FactoryBot.create(:admin) }
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
        "0" => {
          "url" => "file:///base/4609321/1.tif",
          "file_name" => "1.tif",
          "file_size" => "100"
        }
      }
    end

    before do
      allow(IngestFolderJob).to receive(:perform_later)
      allow(IngestFoldersJob).to receive(:perform_later)
    end

    context "with one single-volume resource where the directory is the bibid" do
      before do
        stub_bibdata(bib_id: "4609321")
      end

      it "ingests the directory as a single resource" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expected_attributes = {
          directory: "/base/4609321",
          state: "pending",
          visibility: "open",
          member_of_collection_ids: ["1234567"],
          source_metadata_identifier: "4609321"
        }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
      end
    end

    context "when the directory looks like a bibid, but isn't valid" do
      before do
        allow(RemoteRecord).to receive(:retrieve).and_raise(URI::InvalidURIError)
      end

      it "ingests the directory as a single resource" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expected_attributes = {
          directory: "/base/4609321",
          state: "pending",
          visibility: "open",
          member_of_collection_ids: ["1234567"]
        }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
      end
    end

    context "when the directory does not look like a bibid" do
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
          "0" => {
            "url" => "file:///base/June 31/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          }
        }
      end

      it "ingests the directory as a single resource" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expected_attributes = {
          directory: "/base/June 31",
          state: "pending",
          visibility: "open",
          member_of_collection_ids: ["1234567"]
        }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
      end

      context "when no files have been selected" do
        let(:selected_files) do
          {}
        end

        before do
          post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        end

        it "does not enqueue an ingest folder job and alerts the client" do
          expect(IngestFolderJob).not_to have_received(:perform_later)
          expect(flash[:alert]).to eq("Please select some files to ingest.")
          expect(response).to redirect_to(bulk_ingest_show_path)
        end
      end
    end

    context "with two single-volume resources" do
      let(:attributes) do
        {
          workflow: { state: "pending" },
          visibility: "open",
          mvw: false,
          selected_files: selected_files
        }
      end
      let(:selected_files) do
        {
          "0" => {
            "url" => "file:///base/resource1/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          },
          "1" => {
            "url" => "file:///base/resource2/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open", member_of_collection_ids: []))
      end
    end

    context "with files hosted on a cloud-storage provider" do
      let(:selected_files) do
        {
          "0" => {
            "url" => "https://www.example.com/files/1.tif?alt=media",
            "file_name" => "1.tif",
            "file_size" => "100",
            "auth_header" => { "Authorization" => "Bearer secret" }
          },
          "1" => {
            "url" => "https://www.example.com/files/2.tif?alt=media",
            "file_name" => "2.tif",
            "file_size" => "100",
            "auth_header" => { "Authorization" => "Bearer secret" }
          }
        }
      end

      let(:attributes) do
        {
          workflow: { state: "pending" },
          visibility: "open",
          mvw: false,
          selected_files: selected_files
        }
      end

      let(:resources) do
        adapter.query_service.find_all_of_model(model: ScannedResource)
      end

      before do
        allow(BrowseEverythingIngestJob).to receive(:perform_later)
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }

        expect(BrowseEverythingIngestJob).to have_received(:perform_later).with(resources.first.id.to_s, "BulkIngestController", [resources.first.pending_uploads.first.id.to_s])
        expect(BrowseEverythingIngestJob).to have_received(:perform_later).with(resources.last.id.to_s, "BulkIngestController", [resources.last.pending_uploads.first.id.to_s])
      end

      context "when bulk ingesting multi-volume works" do
        let(:attributes) do
          {
            workflow: { state: "pending" },
            visibility: "open",
            mvw: true,
            selected_files: selected_files
          }
        end

        let(:resources) do
          adapter.query_service.find_all_of_model(model: ScannedResource)
        end
        let(:resource) do
          resources.reject { |res| res.member_ids.empty? }.first
        end
        let(:member_resources) { resource.decorate.members }

        before do
          allow(BrowseEverythingIngestJob).to receive(:perform_later)
          post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        end

        it "ingests the file as FileSets on a new member resource for a new parent resource" do
          expect(member_resources.length).to eq(2)

          expect(BrowseEverythingIngestJob).to have_received(:perform_later).with(member_resources.first.id.to_s, "BulkIngestController", member_resources.first.pending_uploads.map(&:id).map(&:to_s))
          expect(BrowseEverythingIngestJob).to have_received(:perform_later).with(member_resources.last.id.to_s, "BulkIngestController", member_resources.last.pending_uploads.map(&:id).map(&:to_s))
        end
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
          "0" => {
            "url" => "file:///base/resource1/vol1/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          },
          "1" => {
            "url" => "file:///base/resource1/vol2/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          }
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
          visibility: "open",
          mvw: true,
          selected_files: selected_files
        }
      end
      let(:selected_files) do
        {
          "0" => {
            "url" => "file:///base/resource1/vol1/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          },
          "1" => {
            "url" => "file:///base/resource1/vol2/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          },
          "2" => {
            "url" => "file:///base/resource2/vol3/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          },
          "3" => {
            "url" => "file:///base/resource2/vol4/1.tif",
            "file_name" => "1.tif",
            "file_size" => "100"
          }
        }
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFoldersJob).to have_received(:perform_later).with(hash_including(directory: "/base", state: "pending", visibility: "open", member_of_collection_ids: []))
      end
    end
  end
end
