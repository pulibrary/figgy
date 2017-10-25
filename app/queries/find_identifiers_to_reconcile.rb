# frozen_string_literal: true
class FindIdentifiersToReconcile
  def self.queries
    [:find_identifiers_to_reconcile]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_identifiers_to_reconcile
    run_query(query)
  end

  def query
    <<-SQL
      SELECT * FROM orm_resources
      WHERE internal_resource='ScannedResource'
      AND orm_resources.metadata @> '{"identifier": []}'
      AND orm_resources.metadata @> '{"source_metadata_identifier": []}'
      AND NOT orm_resources.metadata @> '{"imported_metadata":[{"identifier": []}]}'
    SQL
  end

  def run_query(query)
    orm_class.find_by_sql([query]).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
