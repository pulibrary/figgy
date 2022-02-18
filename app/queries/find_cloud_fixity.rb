# frozen_string_literal: true

class FindCloudFixity
  def self.queries
    [:find_cloud_fixity]
  end

  attr_reader :query_service
  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def query(order_by_property: "updated_at", order_by: "ASC")
    <<-SQL
      select * FROM orm_resources WHERE
      metadata @> ? AND internal_resource = ?
      ORDER BY #{order_by_property} #{order_by} LIMIT ?
    SQL
  end

  def find_cloud_fixity(status:, sort: "ASC", limit: 50, order_by_property: "updated_at", model: Event)
    internal_array = {"status" => [status]}
    run_query(query(order_by_property: order_by_property, order_by: sort), internal_array.to_json, model.to_s, limit)
  end
end
