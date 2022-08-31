# frozen_string_literal: true
class EphemeraBox < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :title, Valkyrie::Types::Set
  attribute :barcode, Valkyrie::Types::Set
  attribute :drive_barcode, Valkyrie::Types::Set
  attribute :box_number, Valkyrie::Types::Set
  attribute :shipped_date, Valkyrie::Types::Set
  attribute :received_date, Valkyrie::Types::Set
  attribute :tracking_number, Valkyrie::Types::Set
  attribute :visibility
  attribute :downloadable
  attribute :rights_statement
  attribute :rights_note
  attribute :state
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :thumbnail_id
  attribute :local_identifier
  attribute :cached_parent_id, Valkyrie::Types::ID.optional
  attribute :embargo_date, Valkyrie::Types::Date.optional

  def title
    ["Ephemera Box"]
  end

  # Inherit edit users from parent Project, to enable external contributors.
  def edit_users
    return self[:edit_users] unless persisted?
    (self[:edit_users] + (Wayfinder.for(self).ephemera_project&.edit_users || [])).uniq
  end
end
