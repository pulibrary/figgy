# frozen_string_literal: true

class Preserver::BlindImporter::FileMetadataAdapter::QueryService
  # Wayfinder so that FileMetadataResources can return a parent used by
  # Preserver::NestedStoragePath, as a way to figure out where a JSON or binary file would
  # be stored in a nested hierarchy.
  class BlindImporterMetadataWayfinder < BaseWayfinder
    def parent
      return nil if resource.ancestors.blank?
      parent = resource.ancestors.last
      remaining_ancestors = resource.ancestors[0..-2]
      resource.class.new(id: parent.id, new_record: false, ancestors: remaining_ancestors)
    end
  end
end
