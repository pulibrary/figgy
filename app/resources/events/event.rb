# frozen_string_literal: true
# Models events which modify resources

class Event < Valkyrie::Resource
  enable_optimistic_locking

  attribute :type, Valkyrie::Types::String
  attribute :status, Valkyrie::Types::String

  # the PreservationObject this Event is associated with
  attribute :resource_id, Valkyrie::Types::ID

  # the property within the PreservationObject that contains the file we are related to
  # e.g., binary_nodes or metadata_nodes
  attribute :child_property, Valkyrie::Types::String

  # the ID of the FileMetadata instance we are attached to
  attribute :child_id, Valkyrie::Types::ID
  attribute :message, Valkyrie::Types::String
end
