# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileMetadataController, type: :controller do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }

  before do
    allow(MosaicJob).to receive(:perform_later)
  end

  after(:all) do
    # Clean up mosaic.json documents and cloud rasters after test suite
    FileUtils.rm_rf(Figgy.config["test_cloud_geo_derivative_path"])
  end

  describe "#tilejson" do
    with_queue_adapter :inline
    it "redirects to the tilejson URL" do
      raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")

      get :tilejson, params: { id: raster_set.id, format: :json }

      expect(response).to redirect_to "https://map-tiles-test.example.com/#{raster_set.id.to_s.tr('-', '')}/mosaicjson/tilejson.json"
    end
    it "returns not_found if not given a mosaic" do
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource)

      get :tilejson, params: { id: scanned_resource.id, format: :json }

      expect(response.status).to eq 404
    end
  end

  describe "#metadata" do
    let(:query_service) { ChangeSetPersister.default.query_service }

    context "with a RasterSet" do
      with_queue_adapter :inline

      it "returns json with the mosaic uri" do
        mosaic_generator = instance_double(MosaicGenerator)
        allow(mosaic_generator).to receive(:run).and_return(true)
        allow(MosaicGenerator).to receive(:new).and_return(mosaic_generator)
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        get :metadata, params: { id: raster_set.id, format: :json }

        expect(JSON.parse(response.body)["uri"]).to end_with("/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic.json")
      end
    end

    context "with a Raster Resource that's not a Set" do
      it "returns a 404" do
        raster_resource = FactoryBot.create_for_repository(:raster_resource)
        get :metadata, params: { id: raster_resource.id, format: :json }

        expect(response.status).to eq 404
      end
    end

    context "when there's no such resource" do
      it "returns a 404" do
        get :metadata, params: { id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd", format: :json }

        expect(response.status).to eq 404
      end
    end

    context "with a MapSet that has Raster grandchildren" do
      it "returns json with the mosaic uri" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map_with_multiple_clipped_raster_children)
        map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id], id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        mosaic_generator = instance_double(MosaicGenerator)
        allow(mosaic_generator).to receive(:run).and_return(true)
        allow(MosaicGenerator).to receive(:new).and_return(mosaic_generator)
        get :metadata, params: { id: map_set.id, format: :json }

        expect(JSON.parse(response.body)["uri"]).to end_with("/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic.json")
      end
    end

    context "with a RasterResouce with a GeoTiff FileSet" do
      it "returns json with a path to the cloud derivative file" do
        file_set = FactoryBot.create_for_repository(:geo_raster_cloud_file)
        raster = FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set.id])
        get :metadata, params: { id: raster.id, format: :json }

        expect(JSON.parse(response.body)["uri"]).to end_with("s3://test-geo/test-geo/example.tif")
      end
    end

    context "with a ScannedResource" do
      it "returns a 404" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        get :metadata, params: { id: scanned_resource.id, format: :json }

        expect(response.status).to eq 404
      end
    end

    context "with a ScannedResource with a single RasterResource child" do
      it "returns json with a path to the cloud derivative file" do
        file_set = FactoryBot.create_for_repository(:geo_raster_cloud_file)
        raster = FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set.id])
        scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [raster.id])
        get :metadata, params: { id: scanned_map.id, format: :json }

        expect(JSON.parse(response.body)["uri"]).to end_with("s3://test-geo/test-geo/example.tif")
      end
    end
  end
end
