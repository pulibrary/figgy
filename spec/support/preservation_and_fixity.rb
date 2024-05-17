# frozen_string_literal: true
# rubocop:disable Metrics/MethodLength
def create_file_set(cloud_fixity_status:)
  file_set = FactoryBot.create_for_repository(:file_set)
  create_preservation_object(resource_id: file_set.id, event_status: cloud_fixity_status, event_type: :cloud_fixity)
  file_set
end

def create_preservation_object(event_status:, resource_id:, event_type:)
  metadata_node = FileMetadata.new(id: SecureRandom.uuid)
  preservation_object = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource_id, metadata_node: metadata_node)
  FactoryBot.create_for_repository(
    :event,
    type: event_type,
    status: event_status,
    resource_id: preservation_object.id,
    child_id: metadata_node.id,
    child_property: :metadata_node,
    current: true
  )
end
# rubocop:enable Metrics/MethodLength
