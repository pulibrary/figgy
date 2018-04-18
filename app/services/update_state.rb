# frozen_string_literal: true
class UpdateState
  # Update all members of a Collection to have the specified state
  def self.perform(collection_id:, state:, metadata_adapter: Valkyrie.config.metadata_adapter, logger: Valkyrie.logger)
    change_set_persister = PlumChangeSetPersister.new(metadata_adapter: metadata_adapter,
                                                      storage_adapter: Valkyrie.config.storage_adapter)
    c = metadata_adapter.query_service.find_by(id: collection_id)
    c.decorate.members.each do |member|
      logger.info "Updating state to #{state} for #{member}"
      change_set = DynamicChangeSet.new(member)
      change_set.validate(state: state)
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end
  end
end
