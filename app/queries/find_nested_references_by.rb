# frozen_string_literal: true
class FindNestedReferencesBy
  def self.queries
    [:find_nested_references_by]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_nested_references_by(resource:, nested_property:, property:)
    return [] if resource.id.blank?
    run_query(query, nested_property.to_s, property.to_s, resource.id.to_s)
  end

  def query
    <<-SQL
      SELECT member.* FROM orm_resources,
        jsonb_array_elements(orm_resources.metadata -> ?) nested_resources,
        jsonb_array_elements(nested_resources -> ?) WITH ORDINALITY AS b(member, member_pos)
      JOIN orm_resources member ON (b.member->>'id')::uuid = member.id
      WHERE nested_resources #>> '{id, id}' = ?
      ORDER BY b.member_pos
    SQL
  end
end
