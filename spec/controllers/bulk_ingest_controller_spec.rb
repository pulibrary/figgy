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

  describe ".change_set_class" do
    it "accesses the ChangeSet Class used for persisting resources" do
      expect(described_class.change_set_class).to eq DynamicChangeSet
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
    def create_session
      BrowseEverything::SessionModel.create(
        uuid: SecureRandom.uuid,
        session: {
          provider_id: "file_system"
        }.to_json
      )
    end

    def create_upload_for_container_ids(container_ids)
      container_ids.each do |container|
        FileUtils.mkdir_p(container) unless File.exist?(container)
      end
      BrowseEverything::UploadModel.create(
        uuid: SecureRandom.uuid,
        upload: {
          session_id: create_session.uuid,
          container_ids: container_ids
        }.to_json
      )
    end
    # TODO: Remove when it cleans up after itself.
    before do
      FileUtils.rm_rf(Rails.root.join("tmp", "storage"))
    end
    context "Many Single Volumes without Top Level Directory Selection" do
      it "ingests 2 unaffiliated volumes" do
        storage_root = Rails.root.join("tmp", "storage")
        upload = create_upload_for_container_ids(
          [
            storage_root.join("lapidus", "123456"),
            storage_root.join("lapidus", "4609321")
          ]
        )
        attributes =
          {
            workflow: { state: "pending" },
            collections: ["4609321"],
            visibility: "open",
            mvw: false,
            browse_everything: { "uploads" => [upload.uuid] }
          }
        allow(IngestFolderJob).to receive(:perform_later)
        stub_bibdata(bib_id: "123456")
        stub_bibdata(bib_id: "4609321")

        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: storage_root.join("lapidus", "4609321").to_s, state: "pending", visibility: "open", member_of_collection_ids: ["4609321"], source_metadata_identifier: "4609321"))
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: storage_root.join("lapidus", "123456").to_s, state: "pending", visibility: "open", member_of_collection_ids: ["4609321"], source_metadata_identifier: "123456"))
      end
    end
    context "Many Single Volumes with a top level directory" do
      # Many Single Volumes
      # Lapidus
      #  - 123456
      #    page1
      #  - 1234567
      #    page1
      #
      it "ingests 2 unaffiliated volumes" do
        storage_root = Rails.root.join("tmp", "storage")
        upload = create_upload_for_container_ids(
          [
            storage_root.join("lapidus"),
            storage_root.join("lapidus", "123456"),
            storage_root.join("lapidus", "4609321")
          ]
        )
        attributes =
          {
            workflow: { state: "pending" },
            collections: ["4609321"],
            visibility: "open",
            mvw: false,
            browse_everything: { "uploads" => [upload.uuid] }
          }
        allow(IngestFolderJob).to receive(:perform_later)
        stub_bibdata(bib_id: "123456")
        stub_bibdata(bib_id: "4609321")

        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: storage_root.join("lapidus", "4609321").to_s, state: "pending", visibility: "open", member_of_collection_ids: ["4609321"], source_metadata_identifier: "4609321"))
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: storage_root.join("lapidus", "123456").to_s, state: "pending", visibility: "open", member_of_collection_ids: ["4609321"], source_metadata_identifier: "123456"))
      end
    end
  end

  describe "POST #browse_everything_files" do
    let(:file) { File.open(Rails.root.join("spec", "fixtures", "files", "example.tif")) }
    let(:bytestream) { instance_double(ActiveStorage::Blob) }
    let(:upload_file) { double }
    let(:upload_file_id) { "test-upload-file-id" }
    let(:upload) { instance_double(BrowseEverything::Upload) }
    let(:uploads) { [upload.id] }
    let(:upload_id) { "test-upload-id" }
    let(:provider) { BrowseEverything::Provider::FileSystem.new }
    let(:container) { instance_double(BrowseEverything::Container) }
    let(:container_id) { "file:///base/4609321" }
    let(:browse_everything) do
      {
        "uploads" => uploads
      }
    end
    let(:attributes) do
      {
        workflow: { state: "pending" },
        collections: ["1234567"],
        visibility: "open",
        mvw: false,
        browse_everything: browse_everything
      }
    end

    before do
      allow(bytestream).to receive(:download).and_return(file.read)
      allow(upload_file).to receive(:bytestream).and_return(bytestream)
      allow(upload_file).to receive(:name).and_return("example.tif")
      allow(upload_file).to receive(:id).and_return(upload_file_id)
      allow(BrowseEverything::UploadFile).to receive(:find).and_return([upload_file])
      allow(upload).to receive(:provider).and_return(provider)
      allow(upload).to receive(:containers).and_return([container])
      allow(upload).to receive(:files).and_return([upload_file])
      allow(upload).to receive(:id).and_return(upload_id)
      allow(BrowseEverything::Upload).to receive(:find_by).and_return([upload])
      allow(container).to receive(:name).and_return("example")
      allow(container).to receive(:id).and_return(container_id)

      allow(IngestFolderJob).to receive(:perform_later)
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
      let(:container_id) { "file:///base/June 31" }
      let(:container) { instance_double(BrowseEverything::Container) }

      before do
        allow(upload).to receive(:containers).and_return([container])
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
        let(:browse_everything) do
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

    context "with two top-level single-volume resources" do
      let(:bytestream2) { instance_double(ActiveStorage::Blob) }
      let(:upload_file2) { double }
      let(:upload_file2_id) { "file:///base/resource2/1.tif" }
      let(:upload_file_id) { "file:///base/resource1/1.tif" }
      let(:container2) { instance_double(BrowseEverything::Container) }
      let(:container2_id) { "file:///base/resource2" }
      let(:container_id) { "file:///base/resource1" }

      before do
        allow(bytestream2).to receive(:download).and_return(file.read)
        allow(upload_file2).to receive(:bytestream).and_return(bytestream2)
        allow(upload_file2).to receive(:name).and_return("1.tif")
        allow(upload_file2).to receive(:id).and_return(upload_file2_id)
        allow(BrowseEverything::UploadFile).to receive(:find).with([]).and_return([upload_file2])
        allow(upload_file).to receive(:name).and_return("1.tif")

        allow(container2).to receive(:name).and_return("resource2")
        allow(container2).to receive(:id).and_return(container2_id)
        allow(container).to receive(:name).and_return("resource1")

        allow(upload).to receive(:files).and_return([upload_file, upload_file2])
        allow(upload).to receive(:containers).and_return([container, container2])
        allow(upload).to receive(:files).and_return([upload_file, upload_file2])
      end

      # TODO: Make this actually check to see if two IngestFolderJobs are
      # called.
      it "ingests two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: "/base/resource1", state: "pending", visibility: "open", member_of_collection_ids: ["1234567"]))
      end
    end

    context "with files hosted on a cloud-storage provider" do
      let(:provider) { BrowseEverything::Provider::GoogleDrive.new }
      let(:bytestream2) { instance_double(ActiveStorage::Blob) }
      let(:upload_file2_id) { "https://www.example.com/resource2/1.tif" }
      let(:upload_file2) { double }
      let(:upload_file_id) { "https://www.example.com/resource1/1.tif" }
      let(:container2_id) { "https://www.example.com/resource2" }
      let(:container2) { instance_double(BrowseEverything::Container) }
      let(:container_id) { "https://www.example.com/resource1" }

      let(:resources) do
        adapter.query_service.find_all_of_model(model: ScannedResource)
      end

      before do
        allow(bytestream2).to receive(:download).and_return(file.read)
        allow(upload_file2).to receive(:bytestream).and_return(bytestream2)
        allow(upload_file2).to receive(:name).and_return("1.tif")
        allow(upload_file2).to receive(:container_id).and_return(container2_id)
        allow(upload_file2).to receive(:id).and_return(upload_file2_id)

        allow(upload_file).to receive(:container_id).and_return(container_id)
        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file2_id]).and_return([upload_file2])
        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file_id]).and_return([upload_file])

        allow(container2).to receive(:id).and_return(container2_id)
        allow(container2).to receive(:name).and_return("resource2")
        allow(container2).to receive(:parent_id).and_return("parent2")
        allow(container).to receive(:name).and_return("resource1")
        allow(container).to receive(:id).and_return(container_id)
        allow(container).to receive(:parent_id).and_return("parent1")

        allow(upload).to receive(:files).and_return([upload_file, upload_file2])
        allow(upload).to receive(:containers).and_return([container, container2])

        allow(PendingUpload).to receive(:new).and_call_original
      end

      it "ingests the parent as two resources" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(PendingUpload).to have_received(:new).with(
          hash_including(
            upload_id: "test-upload-id",
            upload_file_id: "https://www.example.com/resource1/1.tif"
          )
        )
        expect(PendingUpload).to have_received(:new).with(
          hash_including(
            upload_id: "test-upload-id",
            upload_file_id: "https://www.example.com/resource2/1.tif"
          )
        )
      end

      context "when bulk ingesting multi-volume works" do
        let(:bytestream2) { instance_double(ActiveStorage::Blob) }
        let(:parent_container_id) { "https://www.example.com/parent" }
        let(:parent_container) { instance_double(BrowseEverything::Container) }
        let(:upload_file2_id) { "https://www.example.com/parent/resource2/1.tif" }
        let(:upload_file2) { double }
        let(:upload_file_id) { "https://www.example.com/parent/resource1/1.tif" }
        let(:container2_id) { "https://www.example.com/parent/resource2" }
        let(:container2) { instance_double(BrowseEverything::Container) }
        let(:container_id) { "https://www.example.com/parent/resource1" }

        let(:attributes) do
          {
            workflow: { state: "pending" },
            visibility: "open",
            mvw: true,
            browse_everything: browse_everything
          }
        end

        let(:resources) do
          adapter.query_service.find_all_of_model(model: ScannedResource)
        end
        let(:resource) do
          resources.select { |res| res.member_ids.length == 2 }.first
        end

        before do
          allow(bytestream2).to receive(:download).and_return(file.read)
          allow(upload_file2).to receive(:bytestream).and_return(bytestream2)
          allow(upload_file2).to receive(:name).and_return("1.tif")
          allow(upload_file2).to receive(:container_id).and_return(container2_id)
          allow(upload_file2).to receive(:id).and_return(upload_file2_id)

          allow(upload_file).to receive(:container_id).and_return(container_id)
          allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file2_id]).and_return([upload_file2])
          allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file_id]).and_return([upload_file])

          allow(parent_container).to receive(:id).and_return(parent_container_id)
          allow(parent_container).to receive(:name).and_return("parent")
          allow(container2).to receive(:parent_id).and_return(parent_container_id)
          allow(container2).to receive(:id).and_return(container2_id)
          allow(container2).to receive(:name).and_return("resource2")
          allow(container).to receive(:parent_id).and_return(parent_container_id)
          allow(container).to receive(:name).and_return("resource1")
          allow(container).to receive(:id).and_return(container_id)

          allow(upload).to receive(:files).and_return([upload_file, upload_file2])
          allow(upload).to receive(:containers).and_return([parent_container, container, container2])

          post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        end

        it "ingests the file as FileSets on a new member resource for a new parent resource" do
          expect(PendingUpload).to have_received(:new).with(
            hash_including(
              upload_id: "test-upload-id",
              upload_file_id: "https://www.example.com/parent/resource1/1.tif"
            )
          )
          expect(PendingUpload).to have_received(:new).with(
            hash_including(
              upload_id: "test-upload-id",
              upload_file_id: "https://www.example.com/parent/resource2/1.tif"
            )
          )
          expect(resource.member_ids.length).to eq(2)
          expect(resource.decorate.volumes.first.file_sets.length).to eq(1)
          expect(resource.decorate.volumes.last.file_sets.length).to eq(1)
        end
      end
    end

    # Single MVW (Intened use of this controller if coming from Google Cloud)
    # 123456
    #  - vol1
    #    - page1
    #  - vol2
    #    - page1
    context "with one multi-volume resource" do
      let(:parent_container) { instance_double(BrowseEverything::Container) }
      let(:parent_container_id) { "file://base/parent" }
      let(:bytestream2) { instance_double(ActiveStorage::Blob) }
      let(:upload_file2_id) { "file://base/parent/resource2/1.tif" }
      let(:upload_file2) { double }
      let(:upload_file_id) { "file://base/parent/resource1/1.tif" }
      let(:container2_id) { "file://base/parent/resource2" }
      let(:container2) { instance_double(BrowseEverything::Container) }
      let(:container_id) { "file://base/resource1" }
      let(:attributes) do
        {
          workflow: { state: "pending" },
          collections: ["1234567"],
          visibility: "open",
          mvw: true,
          browse_everything: browse_everything
        }
      end

      before do
        allow(bytestream2).to receive(:download).and_return(file.read)
        allow(upload_file2).to receive(:bytestream).and_return(bytestream2)
        allow(upload_file2).to receive(:name).and_return("1.tif")
        allow(upload_file2).to receive(:id).and_return(upload_file2_id)

        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file2_id]).and_return([upload_file2])
        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file_id]).and_return([upload_file])

        allow(parent_container).to receive(:id).and_return(parent_container_id)
        allow(container2).to receive(:parent_id).and_return(parent_container_id)
        allow(container2).to receive(:id).and_return(container2_id)
        allow(container).to receive(:parent_id).and_return(parent_container_id)
        allow(container).to receive(:id).and_return(container_id)

        allow(upload).to receive(:files).and_return([upload_file, upload_file2])
        allow(upload).to receive(:containers).and_return([parent_container, container, container2])
      end

      it "ingests a multi-volume work with 2 volumes" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: "base/parent", state: "pending", visibility: "open", member_of_collection_ids: ["1234567"]))
      end
    end

    context "with two multi-volume resources" do
      let(:parent_container2) { instance_double(BrowseEverything::Container) }
      let(:parent_container2_id) { "file://base/parent2" }

      let(:bytestream4) { instance_double(ActiveStorage::Blob) }
      let(:upload_file4_id) { "file://base/parent2/resource2/1.tif" }
      let(:upload_file4) { double }

      let(:bytestream3) { instance_double(ActiveStorage::Blob) }
      let(:upload_file3_id) { "file://base/parent2/resource1/1.tif" }
      let(:upload_file3) { double }

      let(:container4_id) { "file://base/parent2/resource2" }
      let(:container4) { instance_double(BrowseEverything::Container) }
      let(:container3_id) { "file://base/parent2/resource1" }
      let(:container3) { instance_double(BrowseEverything::Container) }

      let(:parent_container) { instance_double(BrowseEverything::Container) }
      let(:parent_container_id) { "file://base/parent" }
      let(:bytestream2) { instance_double(ActiveStorage::Blob) }
      let(:upload_file2_id) { "file://base/parent/resource2/1.tif" }
      let(:upload_file2) { double }
      let(:upload_file_id) { "file://base/parent/resource1/1.tif" }
      let(:container2_id) { "file://base/parent/resource2" }
      let(:container2) { instance_double(BrowseEverything::Container) }
      let(:container_id) { "file://base/resource1" }

      let(:attributes) do
        {
          workflow: { state: "pending" },
          collections: ["1234567"],
          visibility: "open",
          mvw: true,
          browse_everything: browse_everything
        }
      end

      before do
        allow(bytestream4).to receive(:download).and_return(file.read)
        allow(upload_file4).to receive(:bytestream).and_return(bytestream4)
        allow(upload_file4).to receive(:name).and_return("1.tif")
        allow(upload_file4).to receive(:id).and_return(upload_file4_id)

        allow(bytestream3).to receive(:download).and_return(file.read)
        allow(upload_file3).to receive(:bytestream).and_return(bytestream3)
        allow(upload_file3).to receive(:name).and_return("1.tif")
        allow(upload_file3).to receive(:id).and_return(upload_file3_id)

        allow(bytestream2).to receive(:download).and_return(file.read)
        allow(upload_file2).to receive(:bytestream).and_return(bytestream2)
        allow(upload_file2).to receive(:name).and_return("1.tif")
        allow(upload_file2).to receive(:id).and_return(upload_file2_id)

        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file4_id]).and_return([upload_file4])
        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file3_id]).and_return([upload_file3])
        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file2_id]).and_return([upload_file2])
        allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file_id]).and_return([upload_file])

        allow(parent_container2).to receive(:id).and_return(parent_container2_id)
        allow(container4).to receive(:parent_id).and_return(parent_container2_id)
        allow(container4).to receive(:id).and_return(container4_id)
        allow(container3).to receive(:parent_id).and_return(parent_container2_id)
        allow(container3).to receive(:id).and_return(container3_id)

        allow(parent_container).to receive(:id).and_return(parent_container_id)
        allow(container2).to receive(:parent_id).and_return(parent_container_id)
        allow(container2).to receive(:id).and_return(container2_id)
        allow(container).to receive(:parent_id).and_return(parent_container_id)
        allow(container).to receive(:id).and_return(container_id)

        allow(upload).to receive(:files).and_return([upload_file, upload_file2, upload_file3, upload_file4])
        allow(upload).to receive(:containers).and_return([parent_container, container, container2, parent_container2, container3, container4])
      end

      # TODO: this test is wrong
      it "Ingests 2 multi-volume works" do
        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(directory: "base/parent", state: "pending", visibility: "open", member_of_collection_ids: ["1234567"]))
      end
    end
  end
end
