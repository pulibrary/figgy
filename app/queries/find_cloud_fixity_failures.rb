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
      SELECT res.* FROM orm_resources AS res WHERE NOT EXISTS (
        SELECT a.* FROM orm_resources AS a WHERE
          a.internal_resource = res.internal_resource AND
          a.metadata @> '{"status": ["SUCCESS"]}' AND
          a.metadata->'resource_id' = res.metadata->'resource_id' AND
          a.metadata->'child_id' = res.metadata->'child_id' AND
          a.metadata->'child_property' = res.metadata->'child_property' AND
          a.updated_at >= res.updated_at
      ) AND
      res.metadata @> ? AND
      res.internal_resource = ?
      ORDER BY res.#{order_by_property} #{order_by}
      LIMIT ?
    SQL
  end

  def find_cloud_fixity_failures(sort: "ASC", limit: 50, order_by_property: "updated_at", status: "FAILURE", model: Event)
    internal_array = {"status" => [status]}
    run_query(query(order_by_property: order_by_property, order_by: sort), internal_array.to_json, model.to_s, limit)
  end
end
