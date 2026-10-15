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
      query_service.connection[relationship_query(count), id: resource.id.to_s, model: model.to_s, property_query: { property => Array.wrap(value) }.to_json].first[:count]
    else
      run_query(relationship_query(count), id: resource.id.to_s, model: model.to_s, property_query: { property => Array.wrap(value) }.to_json)
    end
  end

  def relationship_query(count = false)
    <<-SQL
        WITH RECURSIVE deep_ids(id) AS (
          SELECT (b.member->>'id')::UUID
          FROM orm_resources a,
          jsonb_array_elements(a.metadata->'member_ids') AS b(member)
          WHERE a.id = :id
          UNION
          SELECT (g.member->>'id')::UUID
          FROM deep_ids d
          JOIN orm_resources f ON f.id = d.id,
          jsonb_array_elements(f.metadata->'member_ids') AS g(member)
          WHERE f.internal_resource <> 'FileSet'
        )
        select #{count ? 'COUNT(*) AS count' : 'member.*'} from deep_ids
        JOIN orm_resources member ON member.id = deep_ids.id
        WHERE member.internal_resource = :model
        AND member.metadata @> :property_query
    SQL
  end
end
