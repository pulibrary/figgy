# frozen_string_literal: true

class Tombstone < Valkyrie::Resource
  attribute :resource_id, Valkyrie::Types::ID
  attribute :resource_title
  attribute :resource_original_filename
  attribute :preservation_object, PreservationObject.optional
  attribute :parent_id, Valkyrie::Types::ID
  alias deleted_at created_at
end
