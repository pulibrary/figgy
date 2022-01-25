# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileMetadataController, type: :controller do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }

  after(:all) do
    # Clean up mosaic.json documents and cloud rasters after test suite
    FileUtils.rm_rf(Figgy.config["test_cloud_geo_derivative_path"])
  end

  describe "#metadata" do
    let(:query_service) { ChangeSetPersister.default.query_service }

    context "with a RasterSet" do
      with_queue_adapter :inline

      it "returns json with the fingerprinted mosaic uri" do
        mosaic_generator = instance_double(MosaicGenerator)
        allow(mosaic_generator).to receive(:run).and_return(true)
        allow(MosaicGenerator).to receive(:new).and_return(mosaic_generator)
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
        get :metadata, params: { id: raster_set.id, format: :json }

        expect(JSON.parse(response.body)["uri"]).to end_with("tmp/cloud_geo_derivatives/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic-#{fingerprint}.json")
      end
    end

    context "when a RasterSet is updated" do
      with_queue_adapter :inline

      it "returns json with a different mosaic uri" do
        mosaic_generator = instance_double(MosaicGenerator)
        allow(mosaic_generator).to receive(:run).and_return(true)
        allow(MosaicGenerator).to receive(:new).and_return(mosaic_generator)
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        first_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)

        # Delete file from of raster_set member
        child = Wayfinder.for(raster_set).members.first
        grandchild = Wayfinder.for(child).members.first
        persister.delete(resource: grandchild)
        second_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)

        get :metadata, params: { id: raster_set.id, format: :json }
        expect(JSON.parse(response.body)["uri"]).not_to end_with("tmp/cloud_geo_derivatives/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic-#{first_fingerprint}.json")
        expect(JSON.parse(response.body)["uri"]).to end_with("tmp/cloud_geo_derivatives/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic-#{second_fingerprint}.json")
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

    context "with a ScannedResource" do
      it "returns a 404" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        get :metadata, params: { id: scanned_resource.id, format: :json }

        expect(response.status).to eq 404
      end
    end
  end
end
