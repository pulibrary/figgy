# frozen_string_literal: true

# Events track preservation fixity check activities.
# Multiple current Events will correspond to a given PreservationObject if that preservation object has both metadata and binary files.
class Event < Valkyrie::Resource
  SUCCESS = "SUCCESS"
  FAILURE = "FAILURE"
  REPAIRING = "REPAIRING"

  enable_optimistic_locking

  attribute :type, Valkyrie::Types::String
  attribute :status, Valkyrie::Types::String
  attribute :current, Valkyrie::Types::Bool

  # for cloud_fixity events, the PreservationObject this Event is associated with
  # for local_fixity events, the FileSet this Event is associated with
  attribute :resource_id, Valkyrie::Types::ID

  # the property within the PreservationObject that contains the file we are related to
  # e.g., "binary_node" or "metadata_node"
  attribute :child_property, Valkyrie::Types::String

  # child_id is the ID of the preservation object's binary node (which is a
  # FileMetadata object)
  attribute :child_id, Valkyrie::Types::ID
  attribute :message, Valkyrie::Types::String

  def successful?
    status == SUCCESS
  end

  def failed?
    status == FAILURE
  end

  def repairing?
    status == REPAIRING
  end

  def current?
    current == true
  end
end
