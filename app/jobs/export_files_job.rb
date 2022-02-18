# frozen_string_literal: true

class ExportFilesJob < ApplicationJob
  def perform(resource_id)
    logger.info "Exporting #{resource_id} to disk"
    query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    resource = query_service.find_by(id: resource_id)
    ExportService.export(resource)
  end
end
