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
    run_query(query(since_date))
  end

  def query(since_date)
    <<-SQL
      select * FROM orm_resources
      WHERE metadata->>'archival_collection_code' is not null AND updated_at > '#{since_date}'
    SQL
  end
end
