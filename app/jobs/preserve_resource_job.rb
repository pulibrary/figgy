# frozen_string_literal: true
class PreserveResourceJob < ApplicationJob
  queue_as :low
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter

  def perform(id:)
    resource = query_service.find_by(id: id)
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      change_set = ChangeSet.for(resource)
      Preserver.for(change_set: change_set, change_set_persister: buffered_change_set_persister).preserve!
    end
  end

  def change_set_persister
    ScannedResourcesController.change_set_persister
  end
end
