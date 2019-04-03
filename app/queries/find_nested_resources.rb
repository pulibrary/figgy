# frozen_string_literal: true
class FindNestedResources
  def self.queries
    [:find_nested_resources]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_nested_resources(property:)
    run_query(query, property.to_s)
  end

  def query
    <<-SQL
      SELECT value AS metadata FROM orm_resources,
      jsonb_array_elements(orm_resources.metadata->?)
    SQL
  end
end
