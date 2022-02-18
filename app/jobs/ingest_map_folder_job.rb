# frozen_string_literal: true

class IngestMapFolderJob < ApplicationJob
  def perform(directory:, **attributes)
    Rails.logger.info "Ingesting folder #{directory}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ingest_service = BulkIngestService.new(change_set_persister: buffered_change_set_persister, klass: ScannedMap, logger: Rails.logger)
      ingest_service.attach_dir(base_directory: directory, file_filters: [".tif"], **attributes)
    end
    Rails.logger.info "Imported #{directory}"
  end
end
