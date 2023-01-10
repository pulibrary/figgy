# frozen_string_literal: true

class DeletionMarker < Valkyrie::Resource
  enable_optimistic_locking
  attribute :resource_id, Valkyrie::Types::ID
  attribute :resource_title
  attribute :original_filename
  attribute :preservation_object, PreservationObject.optional
  attribute :parent_id, Valkyrie::Types::ID
  alias deleted_at created_at
end
