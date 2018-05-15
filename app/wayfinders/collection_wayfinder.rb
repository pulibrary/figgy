# frozen_string_literal: true
class CollectionWayfinder < BaseWayfinder
  inverse_relationship_by_property :members, property: :member_of_collection_ids
  inverse_relationship_by_property :media_resources, property: :member_of_collection_ids, model: MediaResource

  # Nested collections are not currently supported
  def parents
    []
  end

  alias collections parents
end
