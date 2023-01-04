# frozen_string_literal: true

# Events track preservation fixity check activities.
# Multiple current Events will correspond to a given PreservationObject if that preservation object has both metadata and binary files.
class Event < Valkyrie::Resource
  enable_optimistic_locking

  attribute :type, Valkyrie::Types::String
  attribute :status, Valkyrie::Types::String
  attribute :current, Valkyrie::Types::Bool

  # the PreservationObject this Event is associated with
  attribute :resource_id, Valkyrie::Types::ID

  # the property within the PreservationObject that contains the file we are related to
  # e.g., "binary_node" or "metadata_node"
  attribute :child_property, Valkyrie::Types::String

  # the ID of the FileMetadata instance we are attached to
  attribute :child_id, Valkyrie::Types::ID
  attribute :message, Valkyrie::Types::String
end
