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

  def find_deep_children_with_property(resource:, model:, property: nil, value: nil, count: false)
    query = relationship_query(count, filter_property: property)
    params = { id: resource.id.to_s, model: model.to_s, property_query: { property => Array.wrap(value) }.to_json }
    if count
      query_service.connection[query, params].first[:count]
    else
      run_query(query, params)
    end
  end

  def relationship_query(count = false, filter_property: nil)
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
        select #{count ? 'COUNT(*) AS count' : 'member.*'} from orm_resources member
        WHERE member.id = ANY(ARRAY(SELECT id FROM deep_ids))
        AND member.internal_resource = :model
        #{'AND member.metadata @> :property_query' if filter_property}
    SQL
  end
end
