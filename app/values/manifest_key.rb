# frozen_string_literal: true

class ManifestKey
  def self.for(resource)
    new(resource: resource, query_service: query_service)
  end

  def self.query_service
    Valkyrie.config.metadata_adapter.query_service
  end

  attr_reader :resource, :query_service
  def initialize(resource:, query_service:)
    @resource = resource
    @query_service = query_service
  end

  def to_s
    # Call #to_f first so the microsecond timestamps carry over.
    "#{resource.class}/#{resource.updated_at.to_f}/#{member_updated_at.to_f}"
  end

  def member_updated_at
    @member_updated_at = query_service.custom_queries.latest_member_timestamp(resource: resource)
  end
end
