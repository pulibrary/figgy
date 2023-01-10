# frozen_string_literal: true
class TombstoneMigrator
  # rubocop:disable Metrics/MethodLength
  def self.call
    counter = 0
    total = query_service.custom_queries.count_all_of_model(model: Tombstone)
    logger = Logger.new(STDOUT)
    query_service.find_all_of_model(model: Tombstone).each do |resource|
      counter += 1
      logger.info("#{counter} / #{total} resources")
      deletion_marker = DeletionMarker.new(
        created_at: resource.created_at,
        resource_id: resource.file_set_id,
        resource_title: resource.file_set_title,
        original_filename: resource.file_set_original_filename,
        preservation_object: resource.preservation_object,
        parent_id: resource.parent_id
      )

      new_change_set = ChangeSet.for(deletion_marker)
      old_change_set = ChangeSet.for(resource)

      change_set_persister.buffer_into_index do |persist|
        persist.save(change_set: new_change_set)
        persist.delete(change_set: old_change_set)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.change_set_persister
    ChangeSetPersister.default
  end

  def self.query_service
    change_set_persister.metadata_adapter.query_service
  end
end
