# frozen_string_literal: true
class ChangeSetPersister
  class RestoreFromDeletionMarkers
    attr_reader :change_set_persister, :change_set

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return if change_set.try(:deletion_marker_restore_ids).blank?
      deletion_markers.each do |deletion_marker|
        next if deletion_marker.preservation_object.blank?
        file_set = Preserver::Importer.from_preservation_object(
          resource: deletion_marker.preservation_object,
          change_set_persister: change_set_persister
        )
        change_set.member_ids += [file_set.id]
        change_set.sync
        change_set.created_file_sets += [file_set]
        change_set_persister.delete(change_set: ChangeSet.for(deletion_marker))
      end
    end

    def deletion_markers
      @deletion_markers ||= query_service.find_many_by_ids(ids: change_set.deletion_marker_restore_ids)
    end

    def query_service
      change_set_persister.metadata_adapter.query_service
    end
  end
end
