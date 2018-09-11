# frozen_string_literal: true
class ScannedResourceWayfinder < BaseWayfinder
  # All valid relationships for a ScannedResource
  relationship_by_property :members, property: :member_ids
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :scanned_resources, property: :member_ids, model: ScannedResource
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :parents, property: :member_ids, singular: true

  def scanned_resources_count
    @scanned_resources_count ||= query_service.custom_queries.count_members(resource: resource, model: ScannedResource)
  end
end
