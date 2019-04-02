# frozen_string_literal: true
class PreserveChildrenJob < ApplicationJob
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter

  def perform(id:)
    resource = query_service.find_by(id: id)
    query_service.find_members(resource: resource).each do |member|
      change_set = DynamicChangeSet.new(member)
      ChangeSetPersister::PreserveResource.new(change_set_persister: change_set_persister, change_set: change_set, post_save_resource: member).run
    end
  end

  def change_set_persister
    ScannedResourcesController.change_set_persister
  end
end
