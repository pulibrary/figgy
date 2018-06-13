# frozen_string_literal: true
class Mutations::UpdateResource < Mutations::BaseMutation
  delegate :query_service, :persister, to: :metadata_adapter
  null true

  argument :id, ID, required: true
  argument :viewing_hint, String, required: false

  field :resource, Types::Resource, null: false
  field :errors, [String], null: true

  def resolve(id:, **attributes)
    resource = query_service.find_by(id: id)
    if ability.can?(:update, resource)
      update_resource(resource, attributes)
    else
      {
        resource: ability.can?(:read, resource) ? resource : nil,
        errors: ["You do not have permissions on this resource."]
      }
    end
  end

  def update_resource(resource, attributes)
    change_set = DynamicChangeSet.new(resource).prepopulate!
    change_set.validate(attributes)
    if change_set.valid?
      {
        resource: change_set_persister.save(change_set: change_set)
      }
    else
      {
        resource: resource,
        errors: change_set.errors.full_messages
      }
    end
  end

  def ability
    context[:ability]
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
