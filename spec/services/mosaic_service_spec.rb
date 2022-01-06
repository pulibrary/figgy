# frozen_string_literal: true
require "rails_helper"
require "shrine/storage/s3"

RSpec.describe MosaicService do
  after(:all) do
    # Clean up mosaic.json documents and cloud rasters after test suite
    FileUtils.rm_rf(Figgy.config["test_cloud_geo_derivative_path"])
  end

  describe "#path" do
    with_queue_adapter :inline

    before do
      # Clean up mosaic.json documents before running each test
      FileUtils.rm_rf(Figgy.config["test_cloud_geo_derivative_path"])
    end

    context "when the file does not exist on the storage adapter" do
      it "generates a default mosaic file and a fingerprinted mosaic file and returns the fingerprinted path" do
        allow(MosaicGenerator).to receive(:new).and_call_original
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        fingerprinted_path = generator.path
        default_path = Rails.root.join("tmp", "cloud_geo_derivatives", "33", "1d", "70", "331d70a54bd94a6580e4763c8f6b34fd", "mosaic.json").to_s
        expect(MosaicGenerator).to have_received(:new).twice
        expect(File.exist?(fingerprinted_path)).to be true
        expect(File.exist?(default_path)).to be true
      end
    end

    context "when the file already exists on the storage adapter" do
      let(:raster_set) { FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd") }

      before do
        described_class.new(resource: raster_set).path
      end

      it "returns the path" do
        allow(MosaicGenerator).to receive(:new)
        query_service = ChangeSetPersister.default.query_service
        path = described_class.new(resource: raster_set).path
        fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
        expect(MosaicGenerator).not_to have_received(:new)
        expect(path).to eq(Rails.root.join("tmp", "cloud_geo_derivatives", "33", "1d", "70", "331d70a54bd94a6580e4763c8f6b34fd", "mosaic-#{fingerprint}.json").to_s)
      end
    end

    context "when there aren't any files on the raster members" do
      it "raises MosaicService::Error" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect { generator.path }.to raise_error("MosaicService::Error")
      end
    end
  end

  describe "#base_path" do
    context "when using the disk storage adapter" do
      it "returns a local path" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect(generator.base_path).to end_with("tmp/cloud_geo_derivatives")
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
        fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
        generator = described_class.new(resource: raster_set)

        expect(generator.mosaic_file_id).to eq("disk://#{Rails.root.join('tmp', 'cloud_geo_derivatives', '33', '1d', '70', '331d70a54bd94a6580e4763c8f6b34fd', "mosaic-#{fingerprint}.json")}")
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
        fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
        generator = described_class.new(resource: raster_set)
        expect(generator.mosaic_file_id).to eq("cloud-geo-derivatives-shrine://33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic-#{fingerprint}.json")
      end
    end
  end
end
