# frozen_string_literal: true

class ChangeSetPersister
  class CreateTombstone
    attr_reader :resource, :change_set_persister
    def initialize(change_set:, change_set_persister: nil, post_save_resource: nil)
      @resource = change_set.resource
      @change_set_persister = change_set_persister
    end

    def run
      return unless resource.is_a?(FileSet) && resource.try(:original_file) && parent
      tombstone = Tombstone.new
      tombstone_change_set = ChangeSet.for(tombstone)
      tombstone_change_set.validate(attributes)
      change_set_persister.save(change_set: tombstone_change_set)
    end

    private

      def attributes
        {
          file_set_id: resource.id,
          file_set_title: resource.title,
          file_set_original_filename: resource.original_file.original_filename,
          preservation_object: preservation_object,
          parent_id: parent.id
        }
      end

      def preservation_object
        wayfinder.preservation_object
      end

      def parent
        wayfinder.parent
      end

      def wayfinder
        @wayfinder ||= Wayfinder.for(resource)
      end
  end
end
