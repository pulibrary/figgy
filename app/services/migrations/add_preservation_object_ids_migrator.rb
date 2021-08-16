# frozen_string_literal: true
class Migrations::AddPreservationObjectIdsMigrator
  def self.call
    new.call
  end

  delegate :query_service, to: :change_set_persister

  def call
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      preservation_objects(buffered_change_set_persister).each do |obj|
        migrate_preservation_object(obj, change_set_persister)
      end
      delete_bad_events(buffered_change_set_persister)
    end
  end

  def delete_bad_events(change_set_persister)
    events = query_service.custom_queries.find_by_property(property: :child_id, value: Valkyrie::ID.new(""))
    events.each do |event|
      change_set_persister.metadata_adapter.persister.delete(resource: event)
    end
  end

  def migrate_preservation_object(preservation_object, change_set_persister)
    # Don't migrate if there's already IDs
    return if metadata_node_id?(preservation_object) && binary_node_ids?(preservation_object)
    (preservation_object.metadata_node.id ||= SecureRandom.uuid) if preservation_object.metadata_node
    preservation_object.binary_nodes.map do |node|
      node.id ||= SecureRandom.uuid
    end
    change_set_persister.metadata_adapter.persister.save(resource: preservation_object)
  end

  def metadata_node_id?(preservation_object)
    preservation_object.metadata_node&.id.present?
  end

  def binary_node_ids?(preservation_object)
    preservation_object.binary_nodes.empty? || preservation_object.binary_nodes.map(&:id).compact.length == preservation_object.binary_nodes.length
  end

  # This is an inlined custom query to be memory efficient. As this class will
  # get removed, it seemed better than writing a whole new custom query.
  def preservation_objects(change_set_persister)
    @preservation_objects ||= change_set_persister.query_service.resources.use_cursor.where(internal_resource: "PreservationObject").lazy.map do |attributes|
      query_service.adapter.resource_factory.to_resource(object: attributes)
    end
  end

  def change_set_persister
    @change_set_persister ||= ChangeSetPersister.default
  end
end
