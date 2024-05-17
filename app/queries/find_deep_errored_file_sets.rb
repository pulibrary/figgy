# frozen_string_literal: true
class FindDeepErroredFileSets
  def self.queries
    [:deep_errored_file_sets_count, :find_deep_errored_file_sets]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def deep_errored_file_sets_count(resource:)
    query_service.connection[relationship_query, id: resource.id.to_s].first[:count]
  end

  def find_deep_errored_file_sets(resource:)
    run_query(relationship_query(false), id: resource.id.to_s)
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
          SELECT mem.*
          FROM deep_members f,
          jsonb_array_elements(f.metadata->'member_ids') AS g(member)
          JOIN orm_resources mem ON (g.member->>'id')::UUID = mem.id
          WHERE f.metadata @> '{"member_ids": [{}]}'
        )

        select #{count ? 'COUNT(*) as count' : '*'} from deep_members,
        jsonb_array_elements(deep_members.metadata->'file_metadata') AS g(file_metadata)
        WHERE internal_resource = 'FileSet'
        AND metadata @> '{ "file_metadata": [ { "error_message": [] } ] }'
        AND g.file_metadata->'error_message' != '[]'::jsonb
    SQL
  end
end
