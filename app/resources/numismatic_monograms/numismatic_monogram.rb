# frozen_string_literal: true
# A symbol made by overlapping or combining letters, typically used as an identifying mark of rulers on coins.
class NumismaticMonogram < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
  attribute :thumbnail_id
  attribute :start_canvas
  attribute :viewing_direction
  attribute :viewing_hint

  attribute :title

  def self.can_have_manifests?
    true
  end
end
