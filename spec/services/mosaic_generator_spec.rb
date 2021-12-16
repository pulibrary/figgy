# frozen_string_literal: true
require "rails_helper"
require "shrine/storage/s3"

RSpec.describe MosaicGenerator do
  describe "#generate" do
    context "when using the disk storage adapter" do
      it "returns a local path" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect(generator.generate).to end_with("tmp/cloud_geo_derivatives/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic.json")
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
        expect(generator.generate).to eq("s3://figgy-bucket/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic.json")
      end
    end
  end
end
