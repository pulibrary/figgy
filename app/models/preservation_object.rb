# frozen_string_literal: true

# A single PreservationObject is used per preserved resource. The
# PreservationObject links to the metadata and binary files.
class PreservationObject < Resource
  enable_optimistic_locking
  # the object we track preservation of
  attribute :preserved_object_id, Valkyrie::Types::ID

  # FileMetadata nested objects for the serialized metadata files
  attribute :metadata_node, FileMetadata.optional
  # the optimistic lock token of the preserved metadata
  attribute :metadata_version, Valkyrie::Types::String

  # FileMetadata nested objects for the preservation copies of the binaries
  attribute :binary_nodes, Valkyrie::Types::Set

  # @return [FileMetadata] Preservation Node in binary_nodes which is the preserved copy of the file_metadata given.
  def binary_node_for(file_metadata)
    binary_nodes.find { |x| x.preservation_copy_of_id == file_metadata.id }
  end
end
