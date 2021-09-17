# frozen_string_literal: true
class CollectionWayfinder < BaseWayfinder
  inverse_relationship_by_property :members, property: :member_of_collection_ids

  # Nested collections are not currently supported
  def parents
    []
  end

  alias collections parents

  def members_count
    @members_count ||= query_service.custom_queries.count_inverse_relationship(resource: resource, property: :member_of_collection_ids)
  end
end
