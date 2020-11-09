# frozen_string_literal: true
class IngestEphemeraJob < ApplicationJob
  def perform(folder_dir, state, project)
    logger.info "Ingesting ephemera folder #{folder_dir}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name
    output = nil
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      output = IngestEphemeraService.new(folder_dir, state, project, buffered_changeset_persister, logger).ingest
    end
    logger.info "Imported #{folder_dir} from pulstore: #{output.id}"
  end
end
