# frozen_string_literal: true
class UpdateFixityJob < ApplicationJob
  queue_as :super_low
  def perform(status:, resource_id:, child_property:, child_id:)
    event_change_set = EventChangeSet.new(Event.new)
    event_change_set.validate(type: :cloud_fixity, status: status, resource_id: resource_id, child_property: child_property.to_sym, child_id: child_id)
    raise "Unable to update fixity. Invalid event: #{event_change_set.errors.full_messages.to_sentence}" unless event_change_set.valid?
    change_set_persister.save(change_set: event_change_set)
  end

  def change_set_persister
    ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:postgres),
      storage_adapter: Valkyrie.config.storage_adapter
    )
  end
end
