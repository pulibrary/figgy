# frozen_string_literal: true
class FindUnrelatedParents
  def self.queries
    [:find_unrelated_parents]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_unrelated_parents_query
    <<-SQL
        SELECT parent.* FROM orm_resources parent,
        jsonb_array_elements(parent.metadata->'member_ids') WITH ORDINALITY AS b(member, member_pos)
        JOIN orm_resources member ON (b.member->>'id')::#{id_type} != member.id WHERE member.id = ?
        AND parent.internal_resource = ?
        ORDER BY b.member_pos
      SQL
  end

  # @param id [Valkyrie::ID, String]
  # @param model [Class, String]
  def find_unrelated_parents(id:, model:)
    query_service.run_query(find_unrelated_parents_query, id, model)
  end

  def id_type
    @id_type ||= orm_class.columns_hash["id"].type
  end
end
