# frozen_string_literal: true
class Mutations::UpdateResource < Mutations::BaseMutation
  null true

  argument :id, ID, required: true
  argument :viewing_hint, String, required: false
  argument :label, String, required: false
  argument :member_ids, [String], required: false
  argument :start_page, String, required: false
  argument :viewing_direction, Types::ViewingDirectionEnum, required: false
  argument :thumbnail_id, String, required: false

  field :resource, Types::Resource, null: false
  field :errors, [String], null: true

  def resolve(id:, **type_attributes)
    resource = query_service.find_by(id: id)
    attributes = self.attributes(type_attributes)
    if ability.can?(:update, resource)
      update_resource(resource, attributes)
    else
      {
        resource: ability.can?(:read, resource) ? resource : nil,
        errors: ["You do not have permissions on this resource."]
      }
    end
  end

  def attributes(type_attributes)
    type_attributes[:title] = type_attributes[:label] if type_attributes[:label].present?
    type_attributes[:start_canvas] = type_attributes[:start_page] if type_attributes[:start_page].present?
    type_attributes.compact
  end

  def update_resource(resource, attributes)
    change_set = ChangeSet.for(resource)
    change_set.validate(attributes)
    if change_set.valid? && valid_member_ids?(change_set, attributes)
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

  def valid_member_ids?(change_set, attributes)
    return true if attributes[:member_ids].blank?
    change_set_ids = query_service.custom_queries.find_persisted_member_ids(resource: change_set.resource)
    member_ids = attributes[:member_ids].map(&:to_s)
    return true if change_set_ids.sort == member_ids.sort
    change_set.errors.add(:member_ids, "can only be used to re-order.")
    false
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
