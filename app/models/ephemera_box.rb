# frozen_string_literal: true
class EphemeraBox < Resource
  include Valkyrie::Resource::AccessControls
<<<<<<< HEAD
=======
  attribute :id, Valkyrie::Types::ID.optional
>>>>>>> d8616123... adds lux order manager to figgy
  attribute :member_ids, Valkyrie::Types::Array
  # member_of_collection_ids is no longer in use for boxes, see #1204
  attribute :member_of_collection_ids
  attribute :title, Valkyrie::Types::Set
  attribute :barcode, Valkyrie::Types::Set
  attribute :drive_barcode, Valkyrie::Types::Set
  attribute :box_number, Valkyrie::Types::Set
  attribute :shipped_date, Valkyrie::Types::Set
  attribute :received_date, Valkyrie::Types::Set
  attribute :tracking_number, Valkyrie::Types::Set
  attribute :visibility
  attribute :rights_statement
  attribute :rights_note
  attribute :state
<<<<<<< HEAD
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
=======
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
>>>>>>> d8616123... adds lux order manager to figgy
  attribute :thumbnail_id
  attribute :local_identifier

  def title
    ["Ephemera Box"]
  end
end
