# frozen_string_literal: true
require "rails_helper"
require "shrine/storage/s3"

RSpec.describe MosaicService do
  describe "#generate" do
    with_queue_adapter :inline

    it "generates mosaic json" do
      raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd", visibility: "restricted")
      document = described_class.new(resource: raster_set).generate
      expect(document["tiles"]["1222"].first).to include("display_raster.tif")
      expect(document["visibility"]).to eq "restricted"
    end

    context "when there aren't any files on the raster members" do
      it "raises MosaicService::Error" do
        raster_set = FactoryBot.create_for_repository(:raster_set, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        generator = described_class.new(resource: raster_set)
        expect { generator.generate }.to raise_error("MosaicService::Error")
      end
    end
  end
end
