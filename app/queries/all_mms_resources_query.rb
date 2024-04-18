# frozen_string_literal: true
class AllMmsResourcesQuery
  def self.queries
    [:all_mms_resources]
  end

  attr_reader :query_service
  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def all_mms_resources
    run_query(all_mms_resources_query)
  end

  def all_mms_resources_query
    <<-SQL
      SELECT * FROM orm_resources WHERE
      internal_resource != 'FileSet' AND
      internal_resource != 'Event' AND
      internal_resource != 'PreservationObject' AND
      internal_resource != 'EphemeraFolder' AND
      metadata ->> 'source_metadata_identifier' ~ '99[0-9]+6421';
    SQL
  end
end
