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
      if change_set.validate(append_or_replace_attributes(member.attributes, attributes))
        change_set_persister.save(change_set: change_set)
      else
        logger.warn "  Failed validation: #{change_set.errors}"
      end
    end
  end

  def self.append_or_replace_attributes(existing_attributes, proposed_attributes)
    incorporated_attributes = {}
    proposed_attributes.each_key do |key|
      incorporated_attributes[key] = case key
                                     when :member_of_collection_ids
                                       existing_attributes[key] << proposed_attributes[key]
                                     else
                                       proposed_attributes[key]
                                     end
    end
    incorporated_attributes
  end
end
