# frozen_string_literal: true
require "rails_helper"

describe MosaicJob do
  with_queue_adapter :inline

  let(:mosaic_service) { instance_double(TileMetadataService) }

  before do
    allow(mosaic_service).to receive(:path)
    allow(TileMetadataService).to receive(:new).and_return(mosaic_service)
  end

  context "with a raster set resource" do
    it "runs the TileMetadataService" do
      raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
      described_class.perform_now(raster_set.id)
      expect(mosaic_service).to have_received(:path)
    end
  end

  context "with a non-set raster resource" do
    it "returns without calling the TileMetadataService" do
      raster_resource = FactoryBot.create_for_repository(:raster_resource)
      described_class.perform_now(raster_resource.id)
      expect(mosaic_service).not_to have_received(:path)
    end
  end
end
