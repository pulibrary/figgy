# frozen_string_literal: true
require "rails_helper"
require "shrine/storage/s3"

RSpec.describe TileMetadataService do
  before do
    allow(MosaicJob).to receive(:perform_later)
  end

  after(:all) do
    # Clean up mosaic.json documents and cloud rasters after test suite
    FileUtils.rm_rf(Figgy.config["test_cloud_geo_derivative_path"])
  end
  let(:cloud_path) { Pathname.new(Figgy.config["test_cloud_geo_derivative_path"]) }

  describe "#path" do
    with_queue_adapter :inline

    before do
      # Clean up mosaic.json documents before running each test
      FileUtils.rm_rf(Figgy.config["test_cloud_geo_derivative_path"])
    end

    it "generates a path to the mosaic file" do
      allow(MosaicGenerator).to receive(:new).and_call_original
      raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
      default_path = described_class.new(resource: raster_set, generate: true).full_path
      expect(MosaicGenerator).to have_received(:new)
      expect(File.exist?(default_path)).to be true
    end

    context "when given a ScannedMap with RasterResources" do
      it "generates a mosaic with the nested raster resource file sets marked as service_targets: tiles" do
        file_set1 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
        file_set2 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
        image_file_set = FactoryBot.create_for_repository(:geo_image_file_set)
        raster1 = FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set1.id])
        raster2 = FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set2.id])
        scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [image_file_set.id, raster1.id, raster2.id])
        map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id])
        generator = instance_double(MosaicGenerator, run: "build")
        allow(MosaicGenerator).to receive(:new).and_return(generator)

        service = described_class.new(resource: map_set, generate: true)

        service.full_path
        expect(MosaicGenerator).to have_received(:new).with(output_path: anything, raster_paths: [file_set1.file_metadata.first.cloud_uri, file_set2.file_metadata.first.cloud_uri])
      end
    end

    context "when there aren't any files on the raster members" do
      it "raises TileMetadataService::Error" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect { generator.full_path }.to raise_error("TileMetadataService::Error")
      end
    end
  end

  describe "#base_path" do
    context "when using the disk storage adapter" do
      it "returns a local path" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect(generator.base_path).to end_with("tmp/cloud_geo_derivatives#{ENV['TEST_ENV_NUMBER']}")
      end
    end

    context "when using the shrine storage adapter" do
      it "returns an s3 path" do
        bucket = instance_double(Aws::S3::Bucket, name: "figgy-bucket")
        shrine = instance_double(Shrine::Storage::S3, bucket: bucket)
        shrine_adapter = instance_double(Valkyrie::Storage::Shrine, shrine: shrine)
        allow(shrine_adapter).to receive(:is_a?).and_return(true)
        allow(Valkyrie::StorageAdapter).to receive(:find).and_return(shrine_adapter)
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect(generator.base_path).to eq("s3://figgy-bucket")
      end
    end
  end

  describe "#mosaic_file_id" do
    let(:query_service) { ChangeSetPersister.default.query_service }

    context "when using the disk storage adapter" do
      it "returns a disk id" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)

        expect(generator.mosaic_file_id).to eq("disk://#{cloud_path.join('33', '1d', '70', '331d70a54bd94a6580e4763c8f6b34fd', 'mosaic.json')}")
      end
    end

    context "when using the shrine storage adapter" do
      it "returns an s3 path" do
        shrine_adapter = Valkyrie::Storage::Shrine.new(
          nil,
          Shrine::NullVerifier,
          Valkyrie::Storage::Disk::BucketedStorage,
          identifier_prefix: "cloud-geo-derivatives"
        )
        allow(Valkyrie::StorageAdapter).to receive(:find).and_return(shrine_adapter)
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect(generator.mosaic_file_id).to eq("cloud-geo-derivatives-shrine://33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic.json")
      end
    end
  end
end
