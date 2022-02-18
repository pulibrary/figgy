# frozen_string_literal: true

class AddEphemeraToCollectionJob < ApplicationJob
  def perform(project_id, collection_id)
    logger.info "starting job"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      AddEphemeraToCollection.new(project_id: project_id,
        collection_id: collection_id,
        change_set_persister: buffered_changeset_persister,
        logger: logger).add_ephemera
    end
    logger.info "job finished"
  end
end
