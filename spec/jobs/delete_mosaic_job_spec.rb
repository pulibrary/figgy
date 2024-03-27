# frozen_string_literal: true
require "rails_helper"

describe DeleteMosaicJob do
  let(:query_service) { ChangeSetPersister.default.query_service }

  after(:all) do
    # Clean up mosaic.json documents and cloud rasters after test suite
    FileUtils.rm_rf(Figgy.config["test_cloud_geo_derivative_path"])
  end

  describe "#perform" do
    context "with a RasterSet" do
      with_queue_adapter :inline

      it "deletes the mosaic.json file" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
        mosaic_path = TileMetadataService.new(resource: raster_set, generate: true).full_path

        expect do
          described_class.perform_now(resource_id: raster_set.id.to_s)
        end.to change { File.exist?(mosaic_path) }.from(true).to(false)
      end
    end

    context "with a ScannedResource" do
      it "does not raise an error" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)

        expect { described_class.perform_now(resource_id: scanned_resource.id.to_s) }.not_to raise_error
      end
    end
  end
end
