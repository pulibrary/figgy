# frozen_string_literal: true
class DeleteMemberJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter
  def perform(id, parent_id = nil)
    member = query_service.find_by(id: id)
    change_set = ChangeSet.for(member)
    # Stash the parent id in append_id so that the deletion marker can save it.
    # If a resource with members is deleted, the deletion marker logic won't be
    # able to save the resource id on the member deletion marker because it's
    # already gone from the database.
    change_set.append_id = parent_id
    change_set_persister.delete(change_set: change_set)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Rails.logger.info("Resource #{id} does not exist, can't delete members")
  end

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
