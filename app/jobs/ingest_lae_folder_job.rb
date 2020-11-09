# frozen_string_literal: true
class IngestLaeFolderJob < ApplicationJob
  def perform(folder_dir)
    logger.info "Ingesting LAE folder #{folder_dir}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name
    output = nil
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      output = BulkIngestService.new(change_set_persister: buffered_changeset_persister, logger: logger)
      output = output.attach_each_dir(base_directory: folder_dir, property: :barcode, file_filters: [".tif"])
    end
    logger.info "Imported #{folder_dir} for LAE"
  end
end
