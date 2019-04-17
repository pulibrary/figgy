# frozen_string_literal: true
class Mutations::UpdateEvent < Mutations::BaseMutation
  null true

  argument :messages, [String], required: false
  argument :modified_resource_ids, [ID], required: true

  field :resource, Types::Resource, null: false
  field :errors, [String], null: true

  def resolve(**type_attributes)
    modified_resource_ids = type_attributes[:modified_resource_ids]
    modified_resource_id = modified_resource_ids.first

    resources = query_service.find_inverse_references_by(property: :modified_resource_ids, id: modified_resource_id)
    resource = resources.first

    if ability.can?(:update, resource)
      update_resource(resource, type_attributes)
    else
      {
        resource: ability.can?(:read, resource) ? resource : nil,
        errors: ["You do not have permissions on this resource."]
      }
    end
  end

  def update_resource(resource, attributes)
    change_set = DynamicChangeSet.new(resource)
    if change_set.validate(attributes)
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

  def change_set_persister
    context[:change_set_persister]
  end

  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
end
