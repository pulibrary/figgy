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
      expect(described_class.storage_adapter).to be_an RetryingDiskAdapter
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
    render_views
    let(:persister) { adapter.persister }

    context "when logged in" do
      it "assigns workflow states based on the resource type" do
        get :show, params: { resource_type: "scanned_maps" }
        expect(assigns(:states)).to eq ["pending", "final_review", "complete_when_processed", "takedown", "flagged"]
      end

      it "assigns collections" do
        collection = persister.save(resource: FactoryBot.build(:collection))
        get :show, params: { resource_type: "scanned_maps" }
        expect(assigns(:collections)).to eq [[collection.title.first, collection.id.to_s]]
      end
      it "doesn't display extra options for ephemera folders" do
        get :show, params: { resource_type: "ephemera_folder" }

        expect(response.body).not_to have_select "workflow_state"
        expect(response.body).not_to have_select "collections"
        expect(response.body).not_to have_select "rights-statement"
        expect(response.body).not_to have_select "holding-location"
        expect(response.body).not_to have_content "Visibility"
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

  describe "POST #bulk_ingest" do
    context "when not logged in" do
      let(:user) { nil }
      it "requests authorization" do
        post :bulk_ingest, params: { resource_type: "scanned_resource" }
        expect(response).to redirect_to("/users/auth/cas")
      end
    end

    context "Many Multi-volume works with a parent directory" do
      it "ingests 2 multi-volume works" do
        attributes =
          {
            workflow: { state: "pending" },
            collections: ["9946093213506421"],
            visibility: "open",
            ingest_directory: "studio_new/DPUL/Santa/ready"
          }
        allow(IngestFolderJob).to receive(:perform_later)
        stub_catalog(bib_id: "991234563506421")
        stub_catalog(bib_id: "9946093213506421")
        stub_catalog(bib_id: "9917912613506421")
        ingest_path = Pathname.new(Figgy.config["ingest_folder_path"]).join("studio_new", "DPUL", "Santa", "ready")

        post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: ingest_path.join("9946093213506421").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["9946093213506421"],
              source_metadata_identifier: "9946093213506421"
            )
          )
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: ingest_path.join("991234563506421").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["9946093213506421"],
              source_metadata_identifier: "991234563506421",
              depositor: user.uid
            )
          )
      end
    end

    context "Many Single Volumes with a top level directory" do
      it "ingests 2 unaffiliated volumes" do
        attributes =
          {
            workflow: { state: "pending" },
            collections: ["9946093213506421"],
            visibility: "open",
            ingest_directory: "examples/lapidus"
          }
        allow(IngestFolderJob).to receive(:perform_later)
        stub_findingaid(pulfa_id: "AC044_c0003")
        stub_catalog(bib_id: "9946093213506421")
        ingest_path = Pathname.new(Figgy.config["ingest_folder_path"]).join("examples")

        post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: ingest_path.join("lapidus", "9946093213506421").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["9946093213506421"],
              source_metadata_identifier: "9946093213506421"
            )
          )
        expect(IngestFolderJob)
          .to have_received(:perform_later)
          .with(
            hash_including(
              directory: ingest_path.join("lapidus", "AC044_c0003").to_s,
              state: "pending",
              visibility: "open",
              member_of_collection_ids: ["9946093213506421"],
              source_metadata_identifier: "AC044_c0003"
            )
          )
      end
    end
  end

  describe "POST #bulk_ingest" do
    let(:attributes) do
      {
        workflow: { state: "pending" },
        collections: ["9912345673506421"],
        visibility: "open",
        ingest_directory: ingest_directory
      }
    end
    let(:user) { FactoryBot.create(:admin) }

    before do
      sign_in user if user
      allow(IngestFolderJob).to receive(:perform_later)
    end
    let(:ingest_path) { Pathname.new(Figgy.config["ingest_folder_path"]) }
    let(:ingest_directory) { "examples/single_volume" }

    # TODO: rewrite or subsume into other tests
    # We do need coverage of the bibid extraction
    context "with one single-volume resource where the directory is the bibid" do
      before do
        stub_catalog(bib_id: "9946093213506421")
      end
      let(:ingest_directory) { "examples/single_volume" }

      it "ingests the directory as a single resource" do
        post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
        expected_attributes = {
          directory: ingest_path.join("examples", "single_volume", "9946093213506421").to_s,
          state: "pending",
          visibility: "open",
          member_of_collection_ids: ["9912345673506421"],
          source_metadata_identifier: "9946093213506421"
        }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
      end

      context "and preserve_file_names is checked" do
        let(:attributes) do
          {
            workflow: { state: "pending" },
            collections: ["1234567"],
            visibility: "open",
            preserve_file_names: "1",
            ingest_directory: ingest_directory
          }
        end
        it "keeps file names" do
          post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
          expected_attributes = {
            directory: ingest_path.join("examples", "single_volume", "9946093213506421").to_s,
            state: "pending",
            visibility: "open",
            member_of_collection_ids: ["1234567"],
            source_metadata_identifier: "9946093213506421",
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
            ingest_directory: ingest_directory,
            holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/15"
          }
        end
        it "adds the holding location" do
          post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
          expected_attributes = {
            directory: ingest_path.join("examples", "single_volume", "9946093213506421").to_s,
            state: "pending",
            visibility: "open",
            member_of_collection_ids: ["1234567"],
            source_metadata_identifier: "9946093213506421",
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
        post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
        expected_attributes = {
          directory: ingest_path.join("examples", "single_volume", "9946093213506421").to_s,
          state: "pending",
          visibility: "open",
          member_of_collection_ids: ["9912345673506421"]
        }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
      end
    end

    context "when the directory does not look like a bibid" do
      let(:ingest_directory) { "examples/not_an_identifier" }

      it "ingests the directory as a single resource" do
        post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
        expected_attributes = {
          directory: ingest_path.join("examples", "not_an_identifier", "June 31").to_s,
          state: "pending",
          visibility: "open",
          member_of_collection_ids: ["9912345673506421"]
        }
        expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(expected_attributes))
      end

      context "when no files have been selected" do
        let(:ingest_directory) { "" }
        before do
          post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }
        end

        it "does not enqueue an ingest folder job and alerts the client" do
          expect(IngestFolderJob).not_to have_received(:perform_later)
          expect(flash[:alert]).to eq("Please select some files to ingest.")
          expect(response).to redirect_to(bulk_ingest_show_path)
        end
      end
    end
  end

  describe "full unstubbed ingest of an LAE ingest" do
    with_queue_adapter :inline
    let(:barcode1) { "32101075851400" }
    let(:barcode2) { "32101075851418" }
    let(:folder1) { FactoryBot.create_for_repository(:ephemera_folder, barcode: [barcode1]) }
    let(:folder2) { FactoryBot.create_for_repository(:ephemera_folder, barcode: [barcode2]) }
    let(:query_service) { metadata_adapter.query_service }
    let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
    before do
      folder1
      folder2
      stub_request(:get, "https://bibdata.princeton.edu/bibliographic/32101075851400/jsonld").and_return(status: 404)
      stub_request(:get, "https://bibdata.princeton.edu/bibliographic/32101075851418/jsonld").and_return(status: 404)
    end
    it "ingests images into the existing ephemera resources" do
      attributes =
        {
          resource_type: "ephemera_folder",
          ingest_directory: "examples/lae"
        }

      post :bulk_ingest, params: { resource_type: "ephemera_folder", **attributes }
      reloaded1 = query_service.find_by(id: folder1.id)
      reloaded2 = query_service.find_by(id: folder2.id)

      expect(reloaded1.member_ids.length).to eq 1
      expect(reloaded2.member_ids.length).to eq 2

      file_sets = query_service.find_members(resource: reloaded2)
      expect(file_sets.flat_map(&:title).to_a).to eq ["1", "2"]
    end
  end

  # Because we're overriding the browse everything upload job, we want to do an
  # integration test here
  describe "full unstubbed ingest of a MVW" do
    with_queue_adapter :inline

    it "ingests a MVW" do
      collection = FactoryBot.create_for_repository(:collection)
      attributes =
        {
          workflow: { state: "pending" },
          collections: [collection.id.to_s],
          visibility: "open",
          resource_type: "scanned_resource",
          ingest_directory: "examples/bulk_ingest",
          rights_statement: RightsStatements.copyright_not_evaluated
        }
      stub_catalog(bib_id: "991234563506421")

      post :bulk_ingest, params: { resource_type: "scanned_resource", **attributes }

      resources = adapter.query_service.find_all_of_model(model: ScannedResource)
      expect(resources.length).to eq 3
      resource = resources.find { |res| res.member_ids.length == 2 }
      expect(resource.source_metadata_identifier).to eq ["991234563506421"]
      expect(resource.member_ids.length).to eq(2)
      expect(resource.decorate.volumes.first.file_sets.length).to eq(1)
      expect(resource.decorate.volumes.last.file_sets.length).to eq(1)
      expect(resource.decorate.collections.first.id).to eq collection.id
      expect(resource.decorate.rights_statement.first).to eq RightsStatements.copyright_not_evaluated
      child_resources = Wayfinder.for(resource).members
      expect(child_resources.map(&:member_of_collection_ids)).to eq [nil, nil]
    end
  end
end
