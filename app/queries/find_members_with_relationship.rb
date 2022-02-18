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
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_members_with_relationship(resource:, relationship:)
    members = query_service.find_members(resource: resource)
    relationship_objects =
      run_query(relationship_query, id: resource.id.to_s, relation: relationship.to_s, relation_query: {relationship => []}.to_json)
    populate_members(relationship, members, relationship_objects)
  end

  def populate_members(relationship, members, relationship_objects)
    members.map do |member|
      member.loaded[relationship] = (member.try(relationship) || []).map do |id|
        relationship_objects.find { |x| x.id == id }
      end.compact
      member
    end
  end

  def relationship_query
    <<-SQL
        SELECT DISTINCT genre.* FROM orm_resources a,
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
