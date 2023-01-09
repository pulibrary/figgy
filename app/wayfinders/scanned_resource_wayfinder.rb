# frozen_string_literal: true
class ScannedResourceWayfinder < BaseWayfinder
  # All valid relationships for a ScannedResource
  relationship_by_property :members, property: :member_ids
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :scanned_resources, property: :member_ids, model: ScannedResource
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :parents, property: :member_ids, singular: true
  inverse_relationship_by_property :child_deletion_markers, property: :parent_id, model: DeletionMarker

  def scanned_resources_count
    @scanned_resources_count ||= query_service.custom_queries.count_members(resource: resource, model: ScannedResource)
  end

  def file_sets_count
    @file_sets_count ||= query_service.custom_queries.count_members(resource: resource, model: FileSet)
  end

  def in_process_file_sets_count
    @in_process_file_sets_count ||= query_service.custom_queries.find_deep_children_with_property(resource: resource, model: FileSet, property: :processing_status, value: "in process", count: true)
  end

  def processed_file_sets_count
    @processed_file_sets_count ||= query_service.custom_queries.find_deep_children_with_property(resource: resource, model: FileSet, property: :processing_status, value: "processed", count: true)
  end

  def members_with_parents
    @members_with_parents ||= members.map do |member|
      member.loaded[:parents] = [resource]
      member
    end
  end

  def playlists
    return [] unless ChangeSet.for(resource).is_a?(RecordingChangeSet)
    @playlists ||=
      begin
        query_service.custom_queries.playlists_from_recording(recording: resource)
      end
  end
end
