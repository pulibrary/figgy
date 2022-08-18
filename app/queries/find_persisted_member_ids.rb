# frozen_string_literal: true
class FindPersistedMemberIds
  def self.queries
    [:find_persisted_member_ids]
  end

  attr_reader :query_service
  delegate :connection, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  # Return all member ids as a result of joind query.
  # This is useful when member_ids contains ids of deleted resources.
  def find_persisted_member_ids(resource:)
    connection[find_persisted_member_ids_query, resource.id.to_s].map do |member|
      member[:id]
    end
  end

  def find_persisted_member_ids_query
    <<-SQL
          SELECT member.id FROM orm_resources a,
          jsonb_array_elements(a.metadata->'member_ids') WITH ORDINALITY AS b(member, member_pos)
          JOIN orm_resources member ON (b.member->>'id')::UUID = member.id WHERE a.id = ?
          ORDER BY b.member_pos
    SQL
  end
end
