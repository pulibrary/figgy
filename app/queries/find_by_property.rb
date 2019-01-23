# frozen_string_literal: true
class FindByProperty
  def self.queries
    [:find_by_property]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_by_property(property:, value:)
    internal_array = { property => Array.wrap(value) }
    run_query(query, internal_array.to_json)
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      metadata @> ?
    SQL
  end
end
