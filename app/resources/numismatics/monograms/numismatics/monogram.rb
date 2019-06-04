# frozen_string_literal: true
# A symbol made by overlapping or combining letters, typically used as an identifying mark of rulers on coins.
module Numismatics
  class Monogram < Resource
    include Valkyrie::Resource::AccessControls
    attribute :member_ids, Valkyrie::Types::Array
    attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
    attribute :replaces
    attribute :start_canvas
    attribute :thumbnail_id
    attribute :title
    attribute :viewing_direction
    attribute :viewing_hint
    attribute :depositor

    def self.can_have_manifests?
      true
    end
  end
end
