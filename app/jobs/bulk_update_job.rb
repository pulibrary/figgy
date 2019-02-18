# frozen_string_literal: true
class BulkUpdateJob < ApplicationJob
  def perform(ids:, args:)
    return unless args[:mark_complete]
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ids.each do |id|
        resource = query_service.find_by(id: id)
        change_set = DynamicChangeSet.new(resource)
        change_set.validate(state: "complete") unless resource.state.include?("complete")
        buffered_change_set_persister.save(change_set: change_set) if change_set.changed?
      end
    end
  end

  private

    def query_service
      metadata_adapter.query_service
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def storage_adapter
      Valkyrie::StorageAdapter.find(:disk_via_copy)
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: storage_adapter
      )
    end
end
