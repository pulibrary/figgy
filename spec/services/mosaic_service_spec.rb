# frozen_string_literal: true
require "rails_helper"
require "shrine/storage/s3"

RSpec.describe MosaicService do
  # calculate the path, including fingerprint
  # check to see if it exists in our storage adapter
  # if so, return the path
  # if not, generate it and return the new path
  describe "#path" do
    context "when the file does not exist on the storage adapter" do
      with_queue_adapter :inline
      it "generates the file and returns the path" do
        allow(MosaicGenerator).to receive(:new).and_call_original
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        path = generator.path
        expect(File.exist?(path)).to be true
        expect(MosaicGenerator).to have_received(:new)
        # Cleanup mosaic file
        File.delete(path)
      end
    end

    context "when the file already exists on the storage adapter" do
      with_queue_adapter :inline

      let(:raster_set) { FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd") }

      before do
        described_class.new(resource: raster_set).path
      end

      it "returns the path" do
        allow(MosaicGenerator).to receive(:new)
        path = described_class.new(resource: raster_set).path
        expect(MosaicGenerator).not_to have_received(:new)
        expect(path).to eq(Rails.root.join("tmp", "cloud_geo_derivatives", "33", "1d", "70", "331d70a54bd94a6580e4763c8f6b34fd", "mosaic.json").to_s)
        # Cleanup mosaic file
        File.delete(path)
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
    context "when using the disk storage adapter" do
      it "returns a disk id" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)

        expect(generator.mosaic_file_id).to eq("disk://#{Rails.root.join('tmp', 'cloud_geo_derivatives', '33', '1d', '70', '331d70a54bd94a6580e4763c8f6b34fd', 'mosaic.json')}")
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