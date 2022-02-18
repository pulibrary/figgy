# frozen_string_literal: true

class ImportBagJob < ApplicationJob
  def perform(resource_id, destination = :bags)
    logger.info "Importing #{resource_id} to BagIt bag in '#{destination}'"
    importer = Bagit::BagImporter.new(
      bag_metadata_adapter: Valkyrie::MetadataAdapter.find(destination),
      bag_storage_adapter: Valkyrie::StorageAdapter.find(destination),
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )

    importer.import(id: resource_id)
  end
end
