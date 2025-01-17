# frozen_string_literal: true
class AddMemberJob < ApplicationJob
  # queue_as :realtime
  queue_as :high

  def perform(resource_id:, parent_id:)
    @resource_id = resource_id
    @parent_id = parent_id

    parent = query_service.find_by(id: @parent_id)
    parent_change_set = ChangeSet.for(parent)
    parent_change_set.member_ids += [@resource_id]
    updated = change_set_persister.save(change_set: parent_change_set)
    raise("Failed to attach the resource #{@resource_id} to the parent #{@parent_id}") unless updated.member_ids.include?(@resource_id)
  end

  private

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def change_set_persister
      ChangeSetPersister.default
    end
end
