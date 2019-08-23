# frozen_string_literal: true
class ChangeSetPersister
  class CreateTombstone
    attr_reader :resource, :change_set_persister
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @resource = change_set.resource
      @change_set_persister = change_set_persister
    end

    def run
      return unless resource.is_a?(FileSet)
      tombstone = Tombstone.new
      tombstone_change_set = DynamicChangeSet.new(tombstone)
      tombstone_change_set.validate(attributes)
      change_set_persister.save(change_set: tombstone_change_set)
    end

    private

      def attributes
        {
          file_set_id: resource.id,
          file_set_title: resource.title,
          file_set_original_filename: resource.original_file.original_filename,
          preservation_object: preservation_object
        }
      end

      def preservation_object
        change_set_persister.query_service.find_inverse_references_by(resource: resource, property: :preserved_object_id).first
      end
  end
end
