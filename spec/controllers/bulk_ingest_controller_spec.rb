# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkIngestController do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  with_queue_adapter :inline

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

    before do
      # Cleanup happens in the IngestFolderJob, stubbed out in these tests
      FileUtils.rm_rf(Rails.root.join("tmp", "storage"))
    end

    context "Many Multi-volume works with a parent directory" do
      it "ingests 2 multi-volume works" do
        storage_root = Rails.root.join("tmp", "storage")
        upload = create_upload_for_container_ids(
          [
            storage_root.join("multi_volume"),
            storage_root.join("multi_volume", "123456"),
            storage_root.join("multi_volume", "4609321"),
            storage_root.join("multi_volume", "4609321", "vol1"),
            storage_root.join("multi_volume", "123456", "vol1"),
            storage_root.join("multi_volume", "4609321", "vol2"),
            storage_root.join("multi_volume", "123456", "vol2")
          ]
        )
        attributes =
          {
            workflow: { state: "pending" },
            collections: ["4609321"],
            visibility: "open",
            browse_everything: { "uploads" => [upload.uuid] }
          }
        allow(IngestFolderJob).to receive(:perform_later)
        stub_bibdata(bib_id: "123456")
        stub_bibdata(bib_id: "4609321")

        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: storage_root.join("multi_volume", "4609321").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["4609321"],
              source_metadata_identifier: "4609321"
            )
          )
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: storage_root.join("multi_volume", "123456").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["4609321"],
              source_metadata_identifier: "123456"
            )
          )
      end
    end

    context "Many Single Volumes with a top level directory" do
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
            browse_everything: { "uploads" => [upload.uuid] }
          }
        allow(IngestFolderJob).to receive(:perform_later)
        stub_bibdata(bib_id: "123456")
        stub_bibdata(bib_id: "4609321")

        post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: storage_root.join("lapidus", "4609321").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["4609321"],
              source_metadata_identifier: "4609321"
            )
          )
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: storage_root.join("lapidus", "123456").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["4609321"],
              source_metadata_identifier: "123456"
            )
          )
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
        browse_everything: browse_everything
      }
    end

    before do
      allow(upload_file).to receive(:purge_bytestream)
      allow(upload_file).to receive(:download).and_return(file.read)
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

    # TODO: rewrite or subsume into other tests
    # We do need coverage of the bibid extraction
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
  end

  context "Individual resources with files hosted on a cloud-storage provider" do
    let(:upload) do
      create_cloud_upload_for_container_ids(
        {
          "https://www.example.com/root" => {
            files: [],
            children:
            {
              "https://www.example.com/root/resource1" => {
                files: ["https://www.example.com/root/resource1/1.tif"],
                children: {}
              },
              "https://www.example.com/root/resource2" => {
                files: ["https://www.example.com/root/resource2/1.tif"],
                children: {}
              }
            }
          }
        },
        "test-upload-id"
      )
    end

    let(:attributes) do
      {
        workflow: { state: "pending" },
        visibility: "open",
        browse_everything: { "uploads" => [upload.id] }
      }
    end

    it "ingests two resources" do
      stub_bibdata(bib_id: "4609321")
      allow(PendingUpload).to receive(:new).and_call_original
      post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
      expect(PendingUpload).to have_received(:new).with(
        hash_including(
          upload_id: "test-upload-id",
          upload_file_id: "https://www.example.com/root/resource1/1.tif"
        )
      )
      expect(PendingUpload).to have_received(:new).with(
        hash_including(
          upload_id: "test-upload-id",
          upload_file_id: "https://www.example.com/root/resource2/1.tif"
        )
      )

      resources = adapter.query_service.find_all_of_model(model: ScannedResource)
      expect(resources.length).to eq 2
    end
  end
  context "bulk ingesting multi-volume works from the cloud" do
    let(:upload) do
      create_cloud_upload_for_container_ids(
        {
          "https://www.example.com/root" => {
            files: [],
            children:
            {
              "https://www.example.com/root/parent" => {
                files: [],
                children: {
                  "https://www.example.com/root/parent/resource1" => {
                    files: ["https://www.example.com/root/parent/resource1/1.tif"],
                    children: {}
                  },
                  "https://www.example.com/root/parent/resource2" => {
                    files: ["https://www.example.com/root/parent/resource2/1.tif"],
                    children: {}
                  }
                }
              }
            }
          }
        },
        "test-upload-id"
      )
    end

    let(:attributes) do
      {
        workflow: { state: "pending" },
        visibility: "open",
        browse_everything: { "uploads" => [upload.id] }
      }
    end

    it "Creates a multi-volume work" do
      stub_bibdata(bib_id: "4609321")
      allow(PendingUpload).to receive(:new).and_call_original
      post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
      expect(PendingUpload).to have_received(:new).with(
        hash_including(
          upload_id: "test-upload-id",
          upload_file_id: "https://www.example.com/root/parent/resource1/1.tif"
        )
      )
      expect(PendingUpload).to have_received(:new).with(
        hash_including(
          upload_id: "test-upload-id",
          upload_file_id: "https://www.example.com/root/parent/resource2/1.tif"
        )
      )

      resources = adapter.query_service.find_all_of_model(model: ScannedResource)
      resource = resources.select { |res| res.member_ids.length == 2 }.first
      expect(resource.member_ids.length).to eq(2)
      expect(resource.decorate.volumes.first.file_sets.length).to eq(1)
      expect(resource.decorate.volumes.last.file_sets.length).to eq(1)
      expect(resources.length).to eq 3
    end
  end

  def create_cloud_upload_for_container_ids(container_hash, upload_id)
    containers = []
    files = []
    file_content = File.open(Rails.root.join("spec", "fixtures", "files", "example.tif")).read
    bytestream = instance_double(ActiveStorage::Blob, download: file_content)
    provider = BrowseEverything::Provider::GoogleDrive.new
    create_cloud_upload_for_child_node(container_hash, nil, containers, files, bytestream)
    upload = instance_double(BrowseEverything::Upload, id: upload_id || SecureRandom.uuid, files: files, containers: containers, provider: provider)
    allow(BrowseEverything::Upload).to receive(:find_by).and_return([upload])
    upload
  end

  # rubocop:disable Metrics/MethodLength
  def create_cloud_upload_for_child_node(container_hash, parent_container_id, containers, files, bytestream)
    container_hash.each do |parent_container, children_and_files|
      container = instance_double(BrowseEverything::Container, id: parent_container, name: parent_container.split("/").last, parent_id: parent_container_id)
      create_cloud_upload_for_child_node(children_and_files[:children], parent_container, containers, files, bytestream) if children_and_files[:children].present?
      files.concat(children_and_files[:files].map do |file|
        file = instance_double(
          BrowseEverything::UploadFile,
          id: file,
          name: file.split("/").last,
          container_id: parent_container,
          bytestream: bytestream,
          download: bytestream.download,
          purge_bytestream: nil
        )
        allow(BrowseEverything::UploadFile).to receive(:find).with([file.id]).and_return([file])
        file
      end)
      containers << container
    end
  end
  # rubocop:enable Metrics/MethodLength
end
