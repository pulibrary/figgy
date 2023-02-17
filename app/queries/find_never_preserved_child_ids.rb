# frozen_string_literal: true
class FindNeverPreservedChildIds
  def self.queries
    [:find_never_preserved_child_ids]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_never_preserved_child_ids(resource:)
    # Get IDs of resources that have preservation objects.
    file_set_ids = adapter.connection[preservation_object_query, id: resource.id.to_s].to_a.map { |x| x[:file_set_id] }
    # Subtract those from member_ids
    resource.member_ids.reject do |member_id|
      file_set_ids.include?(member_id)
    end
  end

  def preservation_object_query
    <<-SQL
      SELECT b.member->>'id' AS file_set_id FROM orm_resources a,
      jsonb_array_elements(a.metadata->'member_ids') AS b(member)
      JOIN orm_resources preservation_object ON b.member->'id' = preservation_object.metadata->'preserved_object_id'->0->'id' WHERE a.id = :id AND preservation_object.internal_resource = 'PreservationObject'
    SQL
  end
end
