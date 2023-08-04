# frozen_string_literal: true

# Finds duplicate current metadata_node cloud_fixity events for the same
# resource_id, and deletes the older one
class DeleteDuplicateFixityEvents
  def self.queries
    [:delete_duplicate_fixity_events]
  end

  attr_reader :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def delete_duplicate_fixity_events
    query_service.connection << delete_query
  end

  def delete_query
    <<-SQL
      DELETE FROM orm_resources a
      USING orm_resources b
      WHERE (a.metadata->'resource_id'->0->>'id')::UUID = (b.metadata->'resource_id'->0->>'id')::UUID
      AND a.id != b.id
      AND a.internal_resource = 'Event'
      AND b.internal_resource = 'Event'
      AND a.metadata @> '{"type":["cloud_fixity"],"current":[true],"child_property":["metadata_node"]}'
      AND b.metadata @> '{"type":["cloud_fixity"],"current":[true],"child_property":["metadata_node"]}'
      AND a.created_at < b.created_at
    SQL
  end
end
