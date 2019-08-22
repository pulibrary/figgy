# frozen_string_literal: true
class Preserver::BlindImporter::FileMetadataAdapter::QueryService
  # Wayfinder so that FileMetadataResources can return a parent used by
  # NestedStoragePath, as a way to figure out where a JSON or binary file would
  # be stored in a nested hierarchy.
  class BlindImporterMetadataWayfinder < Wayfinder
    def parent
      return nil if resource.parents.blank?
      last_parent = resource.parents.last
      remaining_parents = resource.parents[0..-2]
      resource.class.new(id: last_parent.id, new_record: false, parents: remaining_parents)
    end
  end
end
