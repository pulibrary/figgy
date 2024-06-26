# frozen_string_literal: true
class DeepCloudFixityCount
  def self.queries
    [:deep_cloud_fixity_count, :deep_cloud_fixity_member_ids]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def deep_cloud_fixity_count(resource:, status: Event::FAILURE)
    query_service.connection[
      relationship_query,
      id: resource.id.to_s,
      event_metadata: event_metadata(status)
    ].first[:count]
  end

  def deep_cloud_fixity_member_ids(resource:, status: Event::FAILURE)
    query_service.connection[
      relationship_query(false),
      id: resource.id.to_s,
      event_metadata: event_metadata(status)
      ].map { |r| r[:file_set_id] }
  end

  def event_metadata(status)
    %({"current": [true], "type": ["cloud_fixity"], "status": ["#{status}"]})
  end

  def relationship_query(count = true)
    <<-SQL
        WITH RECURSIVE deep_members AS (
          select member.*
          FROM orm_resources a,
          jsonb_array_elements(a.metadata->'member_ids') AS b(member)
          JOIN orm_resources member ON (b.member->>'id')::UUID = member.id
          WHERE a.id = :id
          UNION
          select * from orm_resources WHERE id = :id
          UNION
          SELECT mem.*
          FROM deep_members f,
          jsonb_array_elements(f.metadata->'member_ids') AS g(member)
          JOIN orm_resources mem ON (g.member->>'id')::UUID = mem.id
          WHERE f.metadata @> '{"member_ids": [{}]}'
        ), deep_events AS (
          select member.id AS file_set_id
          from deep_members member
          JOIN orm_resources po ON member.id = (po.metadata->'preserved_object_id'->0->>'id')::UUID
          JOIN orm_resources event ON po.id = (event.metadata->'resource_id'->0->>'id')::UUID
          AND po.internal_resource = 'PreservationObject'
          AND event.internal_resource = 'Event'
          AND event.metadata @> :event_metadata
        )
        select #{count ? 'COUNT(DISTINCT deep_events.file_set_id) AS count' : 'file_set_id'} from deep_events
    SQL
  end
end
