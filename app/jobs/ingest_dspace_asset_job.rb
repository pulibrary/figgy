# frozen_string_literal: true
class IngestDspaceAssetJob < ApplicationJob
  COMMUNITY = "community"
  COLLECTION = "collection"
  ITEM = "item"

  def ingest_service_class
    case @resource_type
    when COMMUNITY
      DspaceCommunityIngester
    when COLLECTION
      DspaceCollectionIngester
    else
      DspaceIngester
    end
  end

  def dspace_service
    @ingester ||= ingest_service_class.new(
      handle: @handle,
      dspace_api_token: @dspace_api_token,
      logger: @logger
    )
  end

  def perform(handle:, dspace_api_token:, resource_type:)
    @handle = handle
    @dspace_api_token = dspace_api_token
    @logger = Rails.logger
    @resource_type = resource_type

    dspace_service.ingest!
  end
end
