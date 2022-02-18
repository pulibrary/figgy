# frozen_string_literal: true

class FindDeepChildrenWithProperty
  def self.queries
    [:find_deep_children_with_property]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_deep_children_with_property(resource:, model:, property:, value:, count: false)
    if count
      query_service.connection[relationship_query(count), id: resource.id.to_s, model: model.to_s, property_query: {property => Array.wrap(value)}.to_json].first[:count]
    else
      run_query(relationship_query(count), id: resource.id.to_s, model: model.to_s, property_query: {property => Array.wrap(value)}.to_json)
    end
  end

  def relationship_query(count = false)
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
        select #{count ? "COUNT(*) AS count" : "*"} from deep_members
        WHERE internal_resource = :model
        AND metadata @> :property_query
    SQL
  end
end
