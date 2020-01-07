# frozen_string_literal: true
class FindByPropertyAndModel
  def self.queries
    [:find_by_property_and_model]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_by_property_and_model(property:, value:, model:)
    internal_array = { property => Array.wrap(value) }
    run_query(query, internal_array.to_json, model)
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      metadata @> ? AND internal_resource = ?
    SQL
  end
end
