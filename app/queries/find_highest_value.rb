# frozen_string_literal: true

class FindHighestValue
  def self.queries
    [:find_highest_value]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  # @param property [Symbol] the property to find the highest value of
  def find_highest_value(property:)
    results = adapter.connection[highest_value_query(property)]
    return unless results&.first
    results.first[:highest]
  end

  def highest_value_query(property)
    <<-SQL
      select CAST(metadata->'#{property}'->>0 as integer) as highest
      from orm_resources
      where metadata->'#{property}'->0 is not null
      order by CAST(metadata->'#{property}'->>0 AS integer) desc limit 1
    SQL
  end
end
