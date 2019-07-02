# frozen_string_literal: true
class FindDeepPreservationObjectCount
  def self.queries
    [:find_deep_preservation_object_count]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_deep_preservation_object_count(resource:)
    query_service.connection[relationship_query, id: resource.id.to_s].first[:count]
  end

  def relationship_query
    <<-SQL
        WITH RECURSIVE deep_members AS (
          select member.*
          FROM orm_resources a,
          jsonb_array_elements(a.metadata->'member_ids') AS b(member)
          JOIN orm_resources member ON (b.member->>'id')::UUID = member.id
          WHERE a.id = :id
          UNION
          SELECT mem.*
          FROM deep_members f,
          jsonb_array_elements(f.metadata->'member_ids') AS g(member)
          JOIN orm_resources mem ON (g.member->>'id')::UUID = mem.id
          WHERE f.metadata @> '{"member_ids": [{}]}'
        ), deep_preservation_objects AS (
          select member.id AS file_set_id, po.*
          from deep_members member
          JOIN orm_resources po ON member.id = (po.metadata->'preserved_object_id'->0->>'id')::UUID
          WHERE member.internal_resource = 'FileSet'
          AND po.internal_resource = 'PreservationObject'
        )
        select COUNT(DISTINCT file_set_id) AS count FROM deep_preservation_objects
    SQL
  end
end
