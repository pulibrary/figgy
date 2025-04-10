# frozen_string_literal: true
class IngestDspaceAssetJob < ApplicationJob
  def dspace_service
    @ingester ||= @ingest_service.new(
      handle: @handle,
      dspace_api_token: @dspace_api_token,
      logger: @logger,
      collection_ids: @collection_ids,
      limit: @limit
    )
  end

  def perform(handle:, dspace_api_token:, ingest_service:, collection_ids:, limit: nil, **attrs)
    @handle = handle
    @dspace_api_token = dspace_api_token
    @logger = Rails.logger
    @ingest_service = ingest_service
    @collection_ids = collection_ids
    @limit = limit

    dspace_service.ingest!(**attrs)
  end
end
