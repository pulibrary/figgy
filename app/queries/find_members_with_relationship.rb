# frozen_string_literal: true
#
# This is a custom query which finds all members of an object as well as
# populates `loaded` with a hash of objects eager loaded from a relationship.
# For instance, if a member has `genres` with a value of
# [Valkyrie::ID.new("bla")], and it's loaded by this query, it will have a
# loaded value of
#
# ```ruby
# {
#   genre: { genre_id => genre_object }
# }
# ```
#
# This can help in reducing N+1 queries.
class FindMembersWithRelationship
  def self.queries
    [:find_members_with_relationship]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_members_with_relationship(resource:, relationship:)
    members = query_service.find_members(resource: resource)
    relationship_objects =
      orm_class.find_by_sql(
        [relationship_query] +
        [{ id: resource.id.to_s, relation: relationship, relation_query: { relationship => [] }.to_json }]
      )
               .group_by { |x| x.attributes["parent_id"] }
    populate_members(relationship, members, relationship_objects)
  end

  def populate_members(relationship, members, relationship_objects)
    members.map do |member|
      member.loaded[relationship] =
        Hash[
          Array.wrap(relationship_objects[member.id.to_s])
               .map { |x| resource_factory.to_resource(object: x) }
               .group_by(&:id).map { |k, v| [k, v.first] }
        ]
      member
    end
  end

  def relationship_query
    <<-SQL
        SELECT genre.*, member.id AS parent_id FROM orm_resources a,
        jsonb_array_elements(a.metadata->'member_ids') AS b(member),
        orm_resources member,
        jsonb_array_elements(member.metadata->:relation) AS c(genre_id),
        orm_resources genre
        WHERE (b.member->>'id')::#{id_type} = member.id AND a.id = :id
        AND member.metadata @> :relation_query
        AND c.genre_id ? 'id'
        AND (c.genre_id->>'id')::#{id_type} = genre.id
    SQL
  end

  def id_type
    "UUID"
  end
end
