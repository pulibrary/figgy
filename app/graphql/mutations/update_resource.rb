# frozen_string_literal: true
class Mutations::UpdateResource < Mutations::BaseMutation
  delegate :query_service, :persister, to: :metadata_adapter
  null true

  argument :id, ID, required: true
  argument :viewing_hint, String, required: false

  field :resource, Types::Resource, null: false
  field :errors, [String], null: true

  def resolve(id:, viewing_hint:)
    resource = query_service.find_by(id: id)
    change_set = DynamicChangeSet.new(resource).prepopulate!
    if change_set.validate(viewing_hint: viewing_hint)
      saved_resource = change_set_persister.save(change_set: change_set)
      {
        resource: saved_resource
      }
    else
      {
        resource: resource,
        errors: change_set.errors.full_messages
      }
    end
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def change_set_persister
    @change_set_persister ||= ChangeSetPersister.new(
      storage_adapter: Valkyrie::StorageAdapter.find(:disk),
      metadata_adapter: metadata_adapter
    )
  end
end
