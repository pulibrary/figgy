# frozen_string_literal: true

class ExportBagJob < ApplicationJob
  def perform(resource_id, destination = :bags)
    logger.info "Exporting #{resource_id} to BagIt bag in '#{destination}'"
    query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    exporter = Bagit::BagExporter.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(destination),
      storage_adapter: Valkyrie::StorageAdapter.find(destination),
      query_service: query_service
    )

    resource = query_service.find_by(id: resource_id)
    exporter.export(resource: resource)
  end
end
