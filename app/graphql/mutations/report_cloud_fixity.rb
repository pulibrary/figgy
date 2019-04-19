# frozen_string_literal: true
class Mutations::ReportCloudFixity < Mutations::BaseMutation
  null true

  argument :preservation_object_id, ID, required: true
  argument :file_metadata_node_id, ID, required: true
  argument :status, String, required: true

  field :resource, Types::Resource, null: false
  field :errors, [String], null: true

  def resolve(preservation_object_id, file_metadata_node_id, status)
    preservation_object = query_service.find_by(id: preservation_object_id)
    file_metadata_node = query_service.find_by(id: file_metadata_node_id)

    if ability.can?(:update, preservation_object)
      create_event(preservation_object, file_metadata_node, status)
    else
      {
        resource: ability.can?(:read, preservation_object) ? preservation_object : nil,
        errors: ["You do not have permissions on this resource."]
      }
    end
  end

  private

    def create_event(preservation_object, file_metadata_node, status)
      event = Event.new
      change_set = EventChangeSet.new(event)
      child_property = if file_metadata_node.preserved_metadata?
                         "metadata_node"
                       else
                         "binary_nodes"
                       end
      if change_set.validate(resource_id: preservation_object.id, child_property: child_property, child_id: file_metadata_node.id, status: status)
        change_set_persister.save(change_set: change_set)
        {
          resource: preservation_object
        }
      else
        {
          resource: preservation_object,
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
