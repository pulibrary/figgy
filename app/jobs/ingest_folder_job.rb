# frozen_string_literal: true
class IngestFolderJob < ApplicationJob
  def perform(directory:, property: nil, change_set_param: nil, class_name: "ScannedResource", file_filters: [], **attributes)
    Rails.logger.info "Ingesting folder #{directory}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ingest_service = BulkIngestService.new(change_set_persister: buffered_change_set_persister, change_set_param: change_set_param, klass: class_name.constantize, logger: Rails.logger)
      file_filters = typed_file_filter(class_name) if file_filters.empty?
      ingest_service.attach_dir(base_directory: directory, property: property, file_filters: file_filters, **attributes)
    end
    Rails.logger.info "Imported #{directory}"
  end

  private

    # Determines the file extension filter based upon the name of the class for the resource
    # @param class_name [String] the name of the class used to determine the file filter
    # @return [String]
    def typed_file_filter(class_name)
      case class_name
      # TODO Update to allow video (need a test)
      when "ScannedResource"
        [".tif", ".wav", ".pdf", ".zip", ".jpg"]
      else
        Rails.logger.warn "Ingesting a folder with an unsupported class: #{class_name}"
        []
      end
    end
end
