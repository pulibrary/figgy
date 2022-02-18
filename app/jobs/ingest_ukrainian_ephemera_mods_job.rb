# frozen_string_literal: true

class IngestUkrainianEphemeraMODSJob < ApplicationJob
  def perform(project, mods, dir)
    logger.info "Ingesting ephemera folder #{dir}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name
    output = nil
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      output = IngestEphemeraMODS::IngestUkrainianEphemeraMODS.new(project, mods, dir, buffered_changeset_persister, logger).ingest
    end
    logger.info "Imported #{dir} from pulstore: #{output.id}"
  end
end
