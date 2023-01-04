# frozen_string_literal: true

# A single PreservationObject is used per preserved resource. The
# PreservationObject links to the metadata and binary files.
class PreservationObject < Resource
  enable_optimistic_locking
  # the object we track preservation of
  attribute :preserved_object_id, Valkyrie::Types::ID

  # FileMetadata nested objects for the serialized metadata files
  attribute :metadata_node, FileMetadata.optional

  # FileMetadata nested objects for the preservation copies of the binaries
  attribute :binary_nodes, Valkyrie::Types::Set
end
