# frozen_string_literal: true
class FindCloudFixityChecked
  def self.queries
    [:find_cloud_fixity_checked]
  end

  attr_reader :query_service
  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def query(order_by_property: "updated_at", order_by: "ASC")
    <<-SQL
      SELECT b.* FROM
        (SELECT json_array_elements(json_array_elements(json_extract_path(a.metadata::json,'file_metadata'))->'file_identifiers') AS file_identifier, a.* FROM orm_resources AS a) AS b
        WHERE b.metadata @> ? AND b.file_identifier->>'id' LIKE 'shrine://%' ORDER BY b.#{order_by_property} #{order_by} LIMIT ?
    SQL
  end

  def find_cloud_fixity_checked(sort: "ASC", limit: 50, order_by_property: "updated_at")
    internal_array = { file_metadata: [{ fixity_success: 1 }] }.to_json
    run_query(query(order_by_property: order_by_property, order_by: sort), internal_array, limit)
  end
end
