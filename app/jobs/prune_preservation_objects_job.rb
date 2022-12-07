# frozen_string_literal: true
class PrunePreservationObjectsJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(resource_id)
    resource = query_service.find_by(id: resource_id)
    preservation_objects = Wayfinder.for(resource).preservation_objects
    preservation_objects.sort_by(&:created_at).reverse.each_with_index do |obj, index|
      next if index.zero?
      change_set_persister.delete(change_set: ChangeSet.for(obj))
    end
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def storage_adapter
      Valkyrie::StorageAdapter.find(:disk)
    end

    def change_set_persister
      ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: storage_adapter
      )
    end
end
