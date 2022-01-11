# frozen_string_literal: true
class MosaicCacheJob < ApplicationJob
  queue_as :high
  delegate :query_service, to: :metadata_adapter

  def perform(resource_id, mosaic_only: true)
    MosaicCacheService.new(resource_id: resource_id, mosaic_only: mosaic_only).invalidate
  end
end
