# frozen_string_literal: true
class ChangeSetPersister
  class CreateDeletionMarker
    attr_reader :resource, :change_set, :change_set_persister
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @change_set = change_set
      @resource = change_set.resource
      @change_set_persister = change_set_persister
    end

    def run
      return if resource.is_a?(PreservationObject) || resource.is_a?(DeletionMarker) || resource.is_a?(Event)

      deletion_marker = DeletionMarker.new
      deletion_marker_change_set = ChangeSet.for(deletion_marker)
      if parent_id
        deletion_marker_change_set.validate(attributes.merge(parent_id: parent_id))
      else
        deletion_marker_change_set.validate(attributes)
      end
      change_set_persister.save(change_set: deletion_marker_change_set)
    end

    private

      def attributes
        {
          resource_id: resource.id,
          resource_title: resource.decorate.try(:title),
          resource_type: resource.class.to_s,
          resource_identifier: resource.try(:identifier),
          resource_source_metadata_identifier: resource.try(:source_metadata_identifier),
          resource_local_identifier: resource.try(:local_identifier),
          resource_archival_collection_code: resource.try(:archival_collection_code),
          original_filename: resource.try(:primary_file)&.original_filename,
          member_of_collection_titles: collection_titles,
          deleted_object: resource,
          preservation_object: preservation_object,
          depositor: resource.try(:depositor)
        }
      end

      def collection_titles
        CollectionIndexer.new(resource: resource).to_solr["member_of_collection_titles_ssim"]
      end

      def parent_id
        parent.try(:id) || change_set.append_id
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
