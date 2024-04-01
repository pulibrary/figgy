# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe VectorResourceDerivativeService do
  with_queue_adapter :inline
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    VectorResourceDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip", "application/zip") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:vector_resource) do
    change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, files: [file]))
  end
  let(:decorated_vector_resources) { query_service.find_members(resource: vector_resource) }
  let(:valid_resource) { decorated_vector_resources.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
  let(:tika_output) { tika_shapefile_output }
  let(:valid_id) { valid_change_set.id }

  describe "#valid?" do
    let(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    context "when given an invalid mime_type" do
      before { allow(valid_file).to receive(:mime_type).and_return(["image/jpeg"]) }
      it "does not validate" do
        expect(valid_file).not_to be_valid
      end
    end
  end

  context "with a valid shapefile" do
    it "creates a thumbnail in the derivatives directory and also stores to the cloud" do
      cloud_file_service = instance_double(CloudFilePermissionsService)
      allow(CloudFilePermissionsService).to receive(:new).and_return(cloud_file_service)
      allow(cloud_file_service).to receive(:run)

      resource = query_service.find_by(id: valid_resource.id)
      thumbnails = resource.file_metadata.find_all { |f| f.label == ["thumbnail.png"] }
      thumbnail_file = Valkyrie::StorageAdapter.find_by(id: thumbnails.first.file_identifiers.first)
      cloud_vector_file_set = resource.file_metadata.find(&:cloud_derivative?)
      cloud_vector_file = Valkyrie::StorageAdapter.find_by(id: cloud_vector_file_set.file_identifiers.first)

      expect(cloud_vector_file_set.use).to eq([Valkyrie::Vocab::PCDMUse.CloudDerivative])
      expect(thumbnail_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["derivative_path"]).to_s)
      expect(cloud_vector_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["test_cloud_geo_derivative_path"]).to_s)
      expect(cloud_file_service).to have_received(:run)
    end
  end

  context "with an invalid shapefile" do
    let(:file) { fixture_file_upload("files/vector/shapefile-no-crs.zip", "application/zip") }

    it "stores an error message on the fileset" do
      expect { valid_resource }.to raise_error(RuntimeError)
      file_set = query_service.find_all_of_model(model: FileSet).first
      expect(file_set.original_file.error_message).to include(/ogr2ogr/)
    end
  end

  describe "#cleanup_derivatives" do
    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(id: valid_change_set.id).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:thumbnail_file?)).to be_empty
      expect(reloaded.file_metadata.select(&:cloud_derivative?)).to be_empty
    end

    it "deletes the error_message" do
      resource = query_service.find_by(id: valid_resource.id)
      resource.original_file.error_message = ["it went poorly"]
      persister.save(resource: resource)
      derivative_service.new(id: resource.id).cleanup_derivatives

      resource = query_service.find_by(id: valid_resource.id)
      expect(resource.original_file.error_message).to be_empty
    end
  end
end
