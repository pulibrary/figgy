# frozen_string_literal: true

class DeletionMarker < Resource
  include Valkyrie::Resource::AccessControls
  attribute :resource_id, Valkyrie::Types::ID
  attribute :resource_title
  attribute :original_filename
  attribute :preservation_object, PreservationObject.optional
  attribute :parent_id, Valkyrie::Types::ID
  alias deleted_at created_at

  def thumbnail_id; end

  def title
    resource_title
  end
end
