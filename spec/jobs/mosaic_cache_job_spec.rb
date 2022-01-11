# frozen_string_literal: true
require "rails_helper"

describe MosaicCacheJob do
  with_queue_adapter :inline

  it "runs the MosaicCacheService" do
    resource_id = "331d70a5-4bd9-4a65-80e4-763c8f6b34fd"
    mosaic_cache_service = instance_double(MosaicCacheService)
    allow(mosaic_cache_service).to receive(:invalidate)
    allow(MosaicCacheService).to receive(:new).and_return(mosaic_cache_service)
    described_class.perform_now(resource_id)
    expect(MosaicCacheService).to have_received(:new).with(resource_id: resource_id, mosaic_only: true)
    expect(mosaic_cache_service).to have_received(:invalidate)
  end
end
