# frozen_string_literal: true
class FindCloudFixityFailures
  def self.queries
    [:find_cloud_fixity_failures]
  end

  attr_reader :query_service
  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def query(order_by_property: "updated_at", order_by: "ASC")
    <<-SQL
      SELECT res.* FROM orm_resources AS res WHERE
      res.metadata @> ? AND
      res.metadata @> '{"current": [true]}' AND
      res.internal_resource = 'Event'
      ORDER BY res.#{order_by_property} #{order_by}
      LIMIT ?
    SQL
  end

  def find_cloud_fixity_failures(sort: "ASC", limit: 50, order_by_property: "updated_at", status: "FAILURE")
    internal_array = { "status" => [status] }
    run_query(query(order_by_property: order_by_property, order_by: sort), internal_array.to_json, limit)
  end
end
