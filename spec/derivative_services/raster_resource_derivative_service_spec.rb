# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe RasterResourceDerivativeService do
  with_queue_adapter :inline
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    RasterResourceDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tif") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:raster_resource) do
    change_set_persister.save(change_set: RasterResourceChangeSet.new(RasterResource.new, files: [file]))
  end
  let(:decorated_raster_resources) { query_service.find_members(resource: raster_resource) }
  let(:valid_resource) { decorated_raster_resources.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
  let(:tika_output) { tika_geotiff_output }
  let(:valid_id) { valid_change_set.id }

  before do
    allow(MosaicJob).to receive(:perform_later)
  end

  describe "#valid?" do
    let(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    context "when given an invalid mime_type" do
      before { allow(valid_file).to receive(:mime_type).and_return(["image/jpeg"]) }
      it "does not validate" do
        expect(valid_file).not_to be_valid
      end
    end
  end

  context "with a valid geotiff" do
    it "creates a display raster intermediate file and a thumbnail in the geo derivatives directory, and also stores to the cloud" do
      cloud_file_service = instance_double(CloudFilePermissionsService)
      allow(CloudFilePermissionsService).to receive(:new).and_return(cloud_file_service)
      allow(cloud_file_service).to receive(:run)

      resource = query_service.find_by(id: valid_resource.id)
      rasters = resource.file_metadata.find_all { |f| f.label == ["display_raster.tif"] }
      thumbnails = resource.file_metadata.find_all { |f| f.label == ["thumbnail.png"] }
      raster_file = Valkyrie::StorageAdapter.find_by(id: rasters.first.file_identifiers.first)
      thumbnail_file = Valkyrie::StorageAdapter.find_by(id: thumbnails.first.file_identifiers.first)
      cloud_raster_file_set = resource.file_metadata.find(&:cloud_derivative?)
      cloud_raster_file = Valkyrie::StorageAdapter.find_by(id: cloud_raster_file_set.file_identifiers.first)

      expect(cloud_raster_file_set.use).to eq([Valkyrie::Vocab::PCDMUse.CloudDerivative])
      expect(raster_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["geo_derivative_path"]).to_s)
      expect(thumbnail_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["geo_derivative_path"]).to_s)
      expect(cloud_raster_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["test_cloud_geo_derivative_path"]).to_s)
      expect(cloud_file_service).to have_received(:run)
    end
  end

  context "with a geotiff with an unsafe filename" do
    let(:file) { fixture_file_upload("files/raster/geotiff_&_unsafe.tif", "image/tif") }
    it "generates derivates without erroring" do
      resource = query_service.find_by(id: valid_resource.id)
      rasters = resource.file_metadata.find_all { |f| f.label == ["display_raster.tif"] }
      raster_file = Valkyrie::StorageAdapter.find_by(id: rasters.first.file_identifiers.first)

      expect(raster_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["geo_derivative_path"]).to_s)
    end
  end

  context "with a non-geo tiff" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tif") }

    it "stores an error message on the fileset" do
      expect { valid_resource }.to raise_error(RuntimeError)
      file_set = query_service.find_all_of_model(model: FileSet).first
      expect(file_set.original_file.error_message).to include(/gdalwarp -q -t_srs EPSG:3857/)
    end
  end

  context "with a raster_set parent" do
    it "runs a mosaic generation job" do
      raster_set = FactoryBot.create_for_repository(:raster_set_with_files, state: "complete")
      child = Wayfinder.for(raster_set).members.first
      change_set = ChangeSet.for(child)
      change_set.files = [fixture_file_upload("files/raster/geotiff.tif", "image/tif")]
      change_set_persister.save(change_set: change_set)
      expect(MosaicJob).to have_received(:perform_later).exactly(3).times
    end
  end

  context "with a raster parent and a map_set ancestor" do
    it "runs a mosaic generation job on the map_set" do
      map_set = FactoryBot.create_for_repository(:map_set)
      child_scanned_map = Wayfinder.for(map_set).members.first
      raster = FactoryBot.create_for_repository(:raster_resource)
      change_set = ChangeSet.for(child_scanned_map)
      change_set.member_ids.push(raster.id)
      change_set_persister.save(change_set: change_set)
      change_set = ChangeSet.for(raster)
      change_set.files = [fixture_file_upload("files/raster/geotiff.tif", "image/tif")]
      change_set_persister.save(change_set: change_set)
      expect(MosaicJob).to have_received(:perform_later).once.with(map_set.id.to_s)
    end
  end

  describe "#cleanup_derivatives" do
    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(id: valid_change_set.id).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:derivative?)).to be_empty
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

  it "runs a mosaic generation job" do
    raster_set = FactoryBot.create_for_repository(:raster_set_with_files, state: "complete")
    child = Wayfinder.for(raster_set).members.first
    file_set_id = child.member_ids.first
    derivative_service.new(id: file_set_id).cleanup_derivatives
    expect(MosaicJob).to have_received(:perform_later).exactly(3).times
  end

  # In production, the cloud derivative generation sometimes fails with a
  # network error, the job re-runs, and the display and thumbnail derivatives are
  # duplicated.
  context "when the service runs twice" do
    it "doesn't duplicate derivatives" do
      raster_resource
      derivative_service.new(id: Wayfinder.for(raster_resource).members.first.id).create_derivatives
      file_set = Wayfinder.for(raster_resource).members.first
      display_rasters = file_set.file_metadata.find_all { |f| f.use == [Valkyrie::Vocab::PCDMUse.ServiceFile] }
      thumbnails = file_set.file_metadata.find_all { |f| f.use == [Valkyrie::Vocab::PCDMUse.ThumbnailImage] }
      expect(display_rasters.count).to eq 1
      expect(thumbnails.count).to eq 1
    end
  end
end
