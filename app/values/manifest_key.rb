# frozen_string_literal: true

# Calculates a unique cache key for use with `Rails.cache.fetch` which
# auto-invalidates when the resource or its children change.
class ManifestKey
  def self.for(resource)
    new(resource: resource, query_service: query_service)
  end

  def self.query_service
    Valkyrie.config.metadata_adapter.query_service
  end

  attr_reader :resource, :query_service
  # @param resource [Valkyrie::Resource]
  # @param query_service [Valkyrie::MetadataAdapter::QueryService]
  def initialize(resource:, query_service:)
    @resource = resource
    @query_service = query_service
  end

  # @return [String] unique cache key.
  def to_s
    # Call #to_f first so the microsecond timestamps carry over.
    "#{resource.class}/#{resource.updated_at.to_f}/#{member_updated_at.to_f}"
  end

  def member_updated_at
    @member_updated_at = query_service.custom_queries.latest_member_timestamp(resource: resource)
  end
end
