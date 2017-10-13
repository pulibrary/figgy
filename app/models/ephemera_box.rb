# frozen_string_literal: true
class EphemeraBox < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :title, Valkyrie::Types::Set
  attribute :barcode, Valkyrie::Types::Set
  attribute :box_number, Valkyrie::Types::Set
  attribute :shipped_date, Valkyrie::Types::Set
  attribute :received_date, Valkyrie::Types::Set
  attribute :tracking_number, Valkyrie::Types::Set
  attribute :visibility
  attribute :rights_statement
  attribute :rights_note
  attribute :state
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :thumbnail_id
  attribute :local_identifier

  def title
    'Ephemera Box'
  end
end
