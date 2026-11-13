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
  let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:raster_resource) do
    change_set_persister.save(change_set: RasterResourceChangeSet.new(RasterResource.new, files: [file]))
  end
  let(:decorated_raster_resources) { query_service.find_members(resource: raster_resource) }
  let(:valid_resource) { decorated_raster_resources.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
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
    let(:temp_dir) { Rails.root.join("tmp", "temp_dir") }

    before do
      Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)
      allow(Hydra::Derivatives).to receive(:temp_file_base).and_return temp_dir
    end

    after do
      FileUtils.rmtree(temp_dir)
    end
    it "stores the display raster to the cloud" do
      cloud_file_service = instance_double(CloudFilePermissionsService)
      allow(CloudFilePermissionsService).to receive(:new).and_return(cloud_file_service)
      allow(cloud_file_service).to receive(:run)

      resource = query_service.find_by(id: valid_resource.id)
      cloud_raster_file_set = resource.file_metadata.find(&:cloud_derivative?)
      cloud_raster_file = Valkyrie::StorageAdapter.find_by(id: cloud_raster_file_set.file_identifiers.first)

      expect(cloud_raster_file_set.use).to eq([::PcdmUse::CloudDerivative])
      expect(cloud_raster_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["test_cloud_geo_derivative_path"]).to_s)
      expect(cloud_file_service).to have_received(:run)

      expect(resource.file_metadata.select(&:thumbnail_file?)).to be_empty

      # Ensure that temporary files and directories are cleaned up
      expect(Dir.empty?(temp_dir)).to be true
    end

    it "creates a pyramidal thumbnail" do
      cloud_file_service = instance_double(CloudFilePermissionsService, run: nil)
      allow(CloudFilePermissionsService).to receive(:new).and_return(cloud_file_service)

      resource = query_service.find_by(id: valid_resource.id)
      pyramidal = resource.pyramidal_derivative

      expect(resource.original_file.mime_type).to eq ["image/tiff; gdal-format=GTiff"]
      expect(pyramidal).not_to be_nil
      expect(pyramidal.label).to eq ["thumbnail.tif"]
      expect(pyramidal.use).to eq [::PcdmUse::ServiceFile]
      expect(pyramidal.mime_type).to eq ["image/tiff"]

      pyramidal_file = Valkyrie::StorageAdapter.find_by(id: pyramidal.file_identifiers.first)
      image = Vips::Image.new_from_file(pyramidal_file.io.path)
      expect(image.has_alpha?).to be true

      # Ensure that temporary files and directories are cleaned up
      expect(Dir.empty?(temp_dir)).to be true
    end
  end

  context "with a geotiff with an unsafe filename" do
    let(:file) { fixture_file_upload("files/raster/geotiff_&_unsafe.tif", "image/tif") }
    it "generates derivates without erroring" do
      resource = query_service.find_by(id: valid_resource.id)
      cloud_raster_file_set = resource.file_metadata.find(&:cloud_derivative?)
      cloud_raster_file = Valkyrie::StorageAdapter.find_by(id: cloud_raster_file_set.file_identifiers.first)

      expect(cloud_raster_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["test_cloud_geo_derivative_path"]).to_s)
    end
  end

  context "when derivative generation fails" do
    it "stores the error message on the file set and re-raises" do
      allow(GeoDerivatives::Runners::RasterDerivatives).to receive(:create).and_raise("gdalwarp failed")

      expect { valid_resource }.to raise_error(RuntimeError, "gdalwarp failed")

      file_set = query_service.find_all_of_model(model: FileSet).first
      expect(file_set.original_file.error_message).to include("gdalwarp failed")
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
      fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: map_set.id)
      expect(MosaicJob).to have_received(:perform_later).once.with(resource_id: map_set.id.to_s, fingerprint: fingerprint)
    end
  end

  describe "#cleanup_derivatives" do
    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(id: valid_change_set.id).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
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
  # network error, the job re-runs, and the cloud derivative and thumbnail derivatives are
  # duplicated.
  context "when the service runs twice" do
    it "doesn't duplicate derivatives" do
      raster_resource
      derivative_service.new(id: Wayfinder.for(raster_resource).members.first.id).create_derivatives
      file_set = Wayfinder.for(raster_resource).members.first
      cloud_derivatives = file_set.file_metadata.find_all { |f| f.use == [::PcdmUse::CloudDerivative] }
      thumbnails = file_set.file_metadata.find_all { |f| f.use == [::PcdmUse::ServiceFile] }
      expect(cloud_derivatives.count).to eq 1
      expect(thumbnails.count).to eq 1
    end
  end
end
