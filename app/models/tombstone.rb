# frozen_string_literal: true

class Tombstone < Valkyrie::Resource
  enable_optimistic_locking
  attribute :file_set_id, Valkyrie::Types::ID
  attribute :file_set_title
  attribute :file_set_original_filename
  attribute :preservation_object, PreservationObject.optional
  attribute :parent_id, Valkyrie::Types::ID
  alias deleted_at created_at
end
