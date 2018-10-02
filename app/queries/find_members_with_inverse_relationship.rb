# frozen_string_literal: true
#
# This is a custom query which finds all members of an object as well as
# populates `loaded` with a hash of objects eager loaded from an inverse relationship.
# For instance, if a member wants to pre-load all its parents and it's loaded
# by this query, it will have a loaded value of
#
# ```ruby
# {
#   inverse_member_ids: [parent]
# }
# ```
#
# You can provide a `key` argument to control what the key in `loaded` will be
# named.
#
# This can help in reducing N+1 queries.
class FindMembersWithInverseRelationship
  def self.queries
    [:find_members_with_inverse_relationship]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_members_with_inverse_relationship(resource:, relationship:, key: nil)
    key ||= :"inverse_#{relationship}"
    members = query_service.find_members(resource: resource)
    relationship_objects =
      run_query(relationship_query, id: resource.id.to_s, relation: relationship.to_s, relation_query: { relationship => [{}] }.to_json)
    populate_members(relationship, members, relationship_objects, key)
  end

  def populate_members(relationship, members, relationship_objects, key)
    members.map do |member|
      member.loaded[key] = relationship_objects.select do |relationship_object|
        relationship_object.try(relationship)&.include?(member.id)
      end
      member
    end
  end

  def relationship_query
    <<-SQL
        SELECT DISTINCT a.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->:relation) AS b(member)
        WHERE (b.member->>'id')::uuid IN (
          SELECT DISTINCT member.id FROM orm_resources a,
          jsonb_array_elements(a.metadata->'member_ids') AS b(member),
          orm_resources member WHERE (b.member->>'id')::uuid = member.id
          AND a.id = :id
        ) AND a.metadata @> :relation_query
    SQL
  end
end
