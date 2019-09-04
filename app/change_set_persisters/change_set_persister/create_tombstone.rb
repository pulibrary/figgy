# frozen_string_literal: true
class ChangeSetPersister
  class CreateTombstone
    attr_reader :resource, :change_set_persister
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @resource = change_set.resource
      @change_set_persister = change_set_persister
    end

    def file_set_with_parent?
      if resource.is_a?(FileSet)
        resource.try(:original_file) && parent
      else
        file_sets = resource.decorate.try(:file_sets)
        return if file_sets.blank?

        file_sets.first.try(:original_file)
      end
    end

    def run
      return unless file_set_with_parent?
      tombstone = Tombstone.new
      tombstone_change_set = DynamicChangeSet.new(tombstone)
      tombstone_change_set.validate(attributes)
      change_set_persister.save(change_set: tombstone_change_set)
    end

    private

      def file_set
        return resource if resource.is_a?(FileSet)

        resource.decorate.file_sets.first
      end

      def original_filename
        file_set.original_file.original_filename
      end

      def attributes
        {
          resource_id: resource.id,
          resource_title: resource.try(:title),
          resource_original_filename: original_filename,
          preservation_object: preservation_object,
          parent_id: parent.try(:id)
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
