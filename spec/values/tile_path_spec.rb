# frozen_string_literal: true

require "rails_helper"

describe TilePath do
  describe "tilejson" do
    context "with a MapSet that has two child ScannedMaps and Raster grandchildren" do
      it "returns a mosaic tilejson path" do
        scanned_map1 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
        scanned_map2 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
        map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map1.id, scanned_map2.id], id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        expect(described_class.new(map_set).tilejson).to eq "https://map-tiles-test.example.com/mosaicjson/tilejson.json?id=331d70a54bd94a6580e4763c8f6b34fd"
      end
    end

    context "with a ScannedMap that has a child RasterResource" do
      it "returns nil" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
        expect(described_class.new(scanned_map).tilejson).to be_nil
      end
    end

    context "with a RasterResouce with a GeoTiff FileSet" do
      it "returns a cog tilejson path" do
        file_set = FactoryBot.create_for_repository(:geo_raster_cloud_file)
        raster = FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set.id], id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        expect(described_class.new(raster).tilejson).to eq "https://map-tiles-test.example.com/cog/tilejson.json?id=331d70a54bd94a6580e4763c8f6b34fd"
      end
    end
  end
end
