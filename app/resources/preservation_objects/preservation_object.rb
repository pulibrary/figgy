# frozen_string_literal: true

class PreservationObject < Resource
  # the object we track preservation of
  attribute :preserved_object_id, Valkyrie::Types::ID

  # FileMetadata nested objects for the serialized metadata files
  attribute :metadata_node, FileMetadata.optional

  # FileMetadata nested objects for the preservation copies of the binaries
  attribute :binary_nodes, Valkyrie::Types::Set
end
