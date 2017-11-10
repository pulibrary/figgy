# frozen_string_literal: true
class PlumImporterJob < ApplicationJob
  def perform(id)
    logger.info "Importing #{id} from Plum"
    change_set_persister = PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:plum_storage),
      characterize: false
    )
    change_set_persister.queue = queue_name
    output = nil
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      output = PlumImporter.new(id: id, change_set_persister: buffered_changeset_persister).import!
    end
    logger.info "Imported #{id} from plum: #{output.id}"
  end
end
