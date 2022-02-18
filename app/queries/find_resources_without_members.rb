# frozen_string_literal: true

class FindResourcesWithoutMembers
  def self.queries
    [:find_resources_without_members]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_resources_without_members(model:)
    run_query(query, model.to_s)
  end

  def query
    <<-SQL
      SELECT *
      FROM orm_resources a
      WHERE a.internal_resource = ?
      AND jsonb_array_length(a.metadata->'member_ids') = 0
    SQL
  end
end
