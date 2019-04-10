# frozen_string_literal: true
class PreserveChildrenJob < ApplicationJob
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter

  def perform(id:)
    resource = query_service.find_by(id: id)
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      query_service.find_members(resource: resource).each do |member|
        change_set = DynamicChangeSet.new(member)
        Preserver.for(change_set: change_set, change_set_persister: buffered_change_set_persister).preserve!
      end
    end
  end

  def change_set_persister
    ScannedResourcesController.change_set_persister
  end
end
