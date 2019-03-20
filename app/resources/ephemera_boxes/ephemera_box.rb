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

  def title
    ["Ephemera Box"]
  end
end
