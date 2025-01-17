# frozen_string_literal: true
class IngestDspaceAssetJob < ApplicationJob
  def ingest_service
    @ingest_service ||= @ingest_service_klass.new(
      handle: @handle,
      dspace_api_token: @dspace_api_token,
      limit: @limit,
      delete_preexisting: @delete_preexisting
    )
  end

  def perform(handle:, dspace_api_token:, ingest_service_klass:,
              limit: nil, delete_preexisting: false,
              **attrs)

    @handle = handle
    @dspace_api_token = dspace_api_token
    @ingest_service_klass = ingest_service_klass

    @limit = limit
    @delete_preexisting = delete_preexisting

    ingest_service.ingest!(**attrs)
  end
end
