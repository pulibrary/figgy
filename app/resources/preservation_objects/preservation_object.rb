# frozen_string_literal: true
class PreservationObject < Resource
  attribute :preserved_object_id, Valkyrie::Types::ID
  attribute :metadata_node, FileMetadata.optional
  attribute :binary_nodes
end
