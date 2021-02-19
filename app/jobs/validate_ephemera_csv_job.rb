# frozen_string_literal: true
class ValidateEphemeraCSVJob < ApplicationJob
  def perform(project_id, csvfile, basedir)
    logger.info "Validating csv file #{csvfile}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name
    output = nil
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      output = IngestEphemeraCSV.new(project_id, csvfile, basedir, buffered_changeset_persister, logger).validate
    end
    logger.info "Validated #{csvfile}: #{output}"
  end
end
