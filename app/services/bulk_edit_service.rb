# frozen_string_literal: true
class BulkEditService
  # Update all members of a Collection to have the given attributes
  def self.perform(collection_id:, attributes:, metadata_adapter: Valkyrie.config.metadata_adapter, logger: Valkyrie.logger)
    change_set_persister = ChangeSetPersister.new(metadata_adapter: metadata_adapter,
                                                  storage_adapter: Valkyrie.config.storage_adapter)
    c = metadata_adapter.query_service.find_by(id: collection_id)
    c.decorate.members.each do |member|
      logger.info "Updating attributes for #{member}"
      change_set = ChangeSet.for(member)
      if change_set.validate(attributes)
        change_set_persister.save(change_set: change_set)
      else
        logger.warn "  Failed validation: #{change_set.errors}"
      end
    end
  end
end
