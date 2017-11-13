# frozen_string_literal: true
class IngestFoldersJob < ApplicationJob
  def perform(directory:, property:, file_filter:)
    Rails.logger.info "Ingesting folder #{directory}"
    change_set_persister = PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ingest_service = BulkIngestService.new(change_set_persister: buffered_change_set_persister, logger: Rails.logger)
      ingest_service.attach_each_dir(base_directory: directory, property: property, file_filter: file_filter)
    end
    Rails.logger.info "Imported #{directory}"
  end
end
