# frozen_string_literal: true
class FindFixityEvents
  def self.queries
    [:find_fixity_events]
  end

  attr_reader :query_service
  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def query(order_by_property: "updated_at", order_by: "ASC")
    <<-SQL
      SELECT * FROM orm_resources WHERE
      metadata @> ? AND
      metadata @> '{"current": [true]}' AND
      internal_resource = 'Event'
      ORDER BY #{order_by_property} #{order_by}
      LIMIT ?
    SQL
  end

  def find_fixity_events(sort: "ASC", limit: 50, order_by_property: "updated_at", status:, type:)
    internal_array = { "status" => [status], "type" => [type] }
    run_query(query(order_by_property: order_by_property, order_by: sort), internal_array.to_json, limit)
  end
end
