# frozen_string_literal: true
class EphemeraBoxChangeSet < Valhalla::ChangeSet
  apply_workflow(WorkflowRegistry.workflow_for(EphemeraBox))
  validates :barcode, :box_number, :visibility, :rights_statement, presence: true

  include VisibilityProperty
  property :barcode, multiple: false, required: true
  property :box_number, multiple: false, required: true
  property :shipped_date, multiple: false, required: false
  property :received_date, multiple: false, required: false
  property :tracking_number, multiple: false, required: false
  property :drive_barcode, multiple: false, required: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  # override the default value defined in VisibilityProperty
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  property :read_groups, multiple: true, required: false
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  delegate :human_readable_type, to: :model
  validate :barcode_valid?
  validate :drive_barcode_valid?

  def barcode_valid?
    return if Barcode.new(Array.wrap(barcode).first).valid?
    errors.add(:barcode, 'has an invalid checkdigit')
  end

  def drive_barcode_valid?
    return if drive_barcode.nil? || drive_barcode.empty? || Barcode.new(Array.wrap(drive_barcode).first).valid?
    errors.add(:drive_barcode, 'has an invalid checkdigit')
  end

  def primary_terms
    [
      :barcode,
      :box_number,
      :shipped_date,
      :received_date,
      :tracking_number,
      :drive_barcode,
      :member_of_collection_ids,
      :append_id
    ]
  end
end
