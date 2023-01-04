# frozen_string_literal: true
class ChangeSetPersister
  class CreateTombstone
    attr_reader :resource, :change_set_persister
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @resource = change_set.resource
      @change_set_persister = change_set_persister
    end

    def run
      return if resource.is_a?(PreservationObject) || resource.is_a?(Tombstone)
      tombstone = Tombstone.new
      tombstone_change_set = ChangeSet.for(tombstone)
      if parent_id
        tombstone_change_set.validate(attributes.merge(parent_id: parent_id))
      else
        tombstone_change_set.validate(attributes)
      end

      change_set_persister.save(change_set: tombstone_change_set)
    end

    private

      def attributes
        {
          file_set_id: resource.id,
          file_set_title: resource.try(:title),
          file_set_original_filename: resource.try(:primary_file)&.original_filename,
          preservation_object: preservation_object
        }
      end

      def parent_id
        parent.try(:id)
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
