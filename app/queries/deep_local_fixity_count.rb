# frozen_string_literal: true
class DeepLocalFixityCount
  def self.queries
    [:deep_local_fixity_count]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def deep_local_fixity_count(resource:, status: "FAILURE")
    query_service.connection[
      relationship_query,
      id: resource.id.to_s,
      member_metadata: member_metadata[status],
      event_metadata: event_metadata[status]
    ].first[:count]
  end

  def member_metadata
    {
      "FAILURE" => '{"file_metadata": [{"fixity_success": 0}]}',
      "SUCCESS" => '{"file_metadata": [{"fixity_success": 1}]}'
    }
  end

  def event_metadata
    {
      "FAILURE" => '{"current": [true], "type": ["local_fixity"], "status": ["FAILURE"]}',
      "SUCCESS" => '{"current": [true], "type": ["local_fixity"], "status": ["SUCCESS"]}'
    }
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
        )
        SELECT COUNT(DISTINCT member.id) from deep_members member
        LEFT JOIN orm_resources event
        ON member.id = (event.metadata->'resource_id'->0->>'id')::UUID
        WHERE member.internal_resource = 'FileSet'
          AND (event.internal_resource = 'Event' OR event IS NULL)
          AND (
            (member.metadata @> :member_metadata)
            OR (event.metadata @> :event_metadata)
          )
    SQL
  end
end
