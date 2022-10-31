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
      expect(described_class.storage_adapter).to be_an Valkyrie::Storage::Disk
    end
  end

  describe ".change_set_persister" do
    it "accesses the ChangeSetPersister" do
      expect(described_class.change_set_persister).to be_a ChangeSetPersister::Basic
      expect(described_class.change_set_persister.metadata_adapter).to be described_class.metadata_adapter
      expect(described_class.change_set_persister.storage_adapter).to be described_class.storage_adapter
    end
  end

  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user if user
  end

  describe "GET #show" do
    let(:persister) { adapter.persister }

    context "when logged in" do
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
      let(:user) { nil }
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
          provider_id: "fast_file_system"
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

    context "when not logged in" do
      let(:user) { nil }
      it "requests authorization" do
        post :browse_everything_files, params: { resource_type: "scanned_resource" }
        expect(response).to redirect_to("/users/auth/cas")
      end
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
        stub_catalog(bib_id: "123456")
        stub_catalog(bib_id: "4609321")

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
              source_metadata_identifier: "123456",
              depositor: user.uid
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
            storage_root.join("lapidus", "AC044_c0003"),
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
        stub_findingaid(pulfa_id: "AC044_c0003")
        stub_catalog(bib_id: "4609321")

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
              directory: storage_root.join("lapidus", "AC044_c0003").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["4609321"],
              source_metadata_identifier: "AC044_c0003"
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
    let(:user) { FactoryBot.create(:admin) }

    before do
      sign_in user if user
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
        stub_catalog(bib_id: "4609321")
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

      context "and preserve_file_names is checked" do
        let(:attributes) do
          {
            workflow: { state: "pending" },
            collections: ["1234567"],
            visibility: "open",
            browse_everything: browse_everything,
            preserve_file_names: "1"
          }
        end
        it "keeps file names" do
          post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
          expected_attributes = {
            directory: "/base/4609321",
            state: "pending",
            visibility: "open",
            member_of_collection_ids: ["1234567"],
            source_metadata_identifier: "4609321",
            preserve_file_names: true
          }
          expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
        end
      end

      context "and a holding location is selected" do
        let(:attributes) do
          {
            workflow: { state: "pending" },
            collections: ["1234567"],
            visibility: "open",
            browse_everything: browse_everything,
            holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/15"
          }
        end
        it "adds the holding location" do
          post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }
          expected_attributes = {
            directory: "/base/4609321",
            state: "pending",
            visibility: "open",
            member_of_collection_ids: ["1234567"],
            source_metadata_identifier: "4609321",
            holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/15"
          }
          expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
        end
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
    with_queue_adapter :inline
    let(:upload) do
      create_cloud_upload_for_container_ids(
        "https://www.example.com/root" => {
          files: [],
          children:
          {
            "https://www.example.com/root/4609321" => {
              files: ["https://www.example.com/root/4609321/1.tif"],
              children: {}
            },
            "https://www.example.com/root/resource2" => {
              files: ["https://www.example.com/root/resource2/1.tif"],
              children: {}
            }
          }
        }
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
      FileUtils.rm_rf(Rails.root.join("tmp", "storage#{ENV['TEST_ENV_NUMBER']}"))
      stub_catalog(bib_id: "4609321")
      post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }

      resources = adapter.query_service.find_all_of_model(model: ScannedResource)
      expect(resources.length).to eq 2
      expect(adapter.query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: "4609321").length).to eq 1
      files = Dir[Rails.root.join("tmp", "storage#{ENV['TEST_ENV_NUMBER']}", "**", "*")].select { |x| File.file?(x) }
      expect(files).to eq []
    end
  end
  context "bulk ingesting multi-volume works from the cloud" do
    with_queue_adapter :inline
    let(:upload) do
      create_cloud_upload_for_container_ids(
        "https://www.example.com/root" => {
          files: [],
          children:
          {
            "https://www.example.com/root/AC044_c0003" => {
              files: [],
              children: {
                "https://www.example.com/root/AC044_c0003/resource1" => {
                  files: ["https://www.example.com/root/AC044_c0003/resource1/1.tif"],
                  children: {}
                },
                "https://www.example.com/root/AC044_c0003/resource2" => {
                  files: ["https://www.example.com/root/AC044_c0003/resource2/1.tif"],
                  children: {}
                }
              }
            }
          }
        }
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
      stub_findingaid(pulfa_id: "AC044_c0003")
      post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }

      resources = adapter.query_service.find_all_of_model(model: ScannedResource)
      resource = resources.find { |res| res.member_ids.length == 2 }
      expect(resource.source_metadata_identifier).to eq ["AC044_c0003"]
      expect(resource.member_ids.length).to eq(2)
      expect(resource.decorate.volumes.first.file_sets.length).to eq(1)
      expect(resource.decorate.volumes.last.file_sets.length).to eq(1)
      expect(resources.length).to eq 3
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Because we're overriding the browse everything upload job, we want to do an
  # integration test here
  describe "full unstubbed ingest of a MVW" do
    with_queue_adapter :inline

    def create_session
      BrowseEverything::Session.build(
        provider_id: "fast_file_system"
      ).tap(&:save)
    end

    def create_upload_for_container_ids(container_ids)
      container_ids.each do |container|
        FileUtils.mkdir_p(container) unless File.exist?(container)
      end
      BrowseEverything::Upload.build(
        container_ids: container_ids,
        session_id: create_session.id
      ).tap(&:save)
    end

    it "ingests a MVW" do
      collection = FactoryBot.create_for_repository(:collection)
      fixture_root = Rails.root.join("spec", "fixtures")
      upload = create_upload_for_container_ids(
        [
          fixture_root.join("bulk_ingest")
        ]
      )
      attributes =
        {
          workflow: { state: "pending" },
          collections: [collection.id.to_s],
          visibility: "open",
          resource_type: "scanned_resource",
          browse_everything: { "uploads" => [upload.uuid] }
        }
      stub_catalog(bib_id: "123456")

      post :browse_everything_files, params: { resource_type: "scanned_resource", **attributes }

      resources = adapter.query_service.find_all_of_model(model: ScannedResource)
      expect(resources.length).to eq 3
      resource = resources.find { |res| res.member_ids.length == 2 }
      expect(resource.source_metadata_identifier).to eq ["123456"]
      expect(resource.member_ids.length).to eq(2)
      expect(resource.decorate.volumes.first.file_sets.length).to eq(1)
      expect(resource.decorate.volumes.last.file_sets.length).to eq(1)
      expect(resource.decorate.collections.first.id).to eq collection.id
    end
  end

  def create_cloud_upload_for_container_ids(container_hash)
    file_content = File.open(Rails.root.join("spec", "fixtures", "files", "example.tif")).read
    provider = HashProvider.new(container_hash, file: file_content)
    allow(BrowseEverything::Provider::GoogleDrive).to receive(:new).and_return(provider)
    be_session = BrowseEverything::Session.build(
      provider_id: "google_drive"
    ).tap(&:save)
    upload = BrowseEverything::Upload.build(
      session_id: be_session.id,
      container_ids: container_hash.keys
    ).tap(&:save)
    upload
  end
end
