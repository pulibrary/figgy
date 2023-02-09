# frozen_string_literal: true

class DeletionMarker < Resource
  include Valkyrie::Resource::AccessControls
  attribute :resource_id, Valkyrie::Types::ID
  attribute :resource_title
  attribute :resource_type
  attribute :resource_identifier
  attribute :resource_source_metadata_identifier
  attribute :resource_local_identifier
  attribute :original_filename
  attribute :preservation_object, PreservationObject.optional
  attribute :parent_id, Valkyrie::Types::ID
  attribute :depositor
  alias deleted_at created_at

  def thumbnail_id; end

  def title
    ["#{resource_title.try(:first)} (Deletion Marker)"]
  end
end
