# frozen_string_literal: true

class UpdatedArchivalResources
  def self.queries
    [:updated_archival_resources]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def updated_archival_resources(since_date:)
    run_query(query, since_date.to_s, {visibility: ["open"]}.to_json)
  end

  def query
    <<-SQL
      select * FROM orm_resources
      WHERE metadata @> '{"archival_collection_code": []}'
        AND metadata @> '{"identifier": []}'
        AND updated_at > ?
        AND metadata @> ?
    SQL
  end
end
