# frozen_string_literal: true

class ChangeSetPersister
  class RestoreTombstones
    attr_reader :change_set_persister, :change_set

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.try(:tombstone_restore_ids).present?
      tombstones.each do |tombstone|
        next unless tombstone.preservation_object.present?
        file_set = Preserver::Importer.from_preservation_object(
          resource: tombstone.preservation_object,
          change_set_persister: change_set_persister
        )
        change_set.member_ids += [file_set.id]
        change_set.sync
        change_set.created_file_sets += [file_set]
        change_set_persister.delete(change_set: ChangeSet.for(tombstone))
      end
    end

    def tombstones
      @tombstones ||= query_service.find_many_by_ids(ids: change_set.tombstone_restore_ids)
    end

    def query_service
      change_set_persister.metadata_adapter.query_service
    end
  end
end
