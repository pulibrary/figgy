# frozen_string_literal: true
class EphemeraBoxChangeSet < ChangeSet
  apply_workflow(BoxWorkflow)

  include VisibilityProperty
  property :barcode, multiple: false, required: true
  property :box_number, multiple: false, required: true
  property :shipped_date, multiple: false, required: false
  property :received_date, multiple: false, required: false
  property :tracking_number, multiple: false, required: false
  property :drive_barcode, multiple: false, required: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  # override the default value defined in VisibilityProperty
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  property :read_groups, multiple: true, required: false
  property :downloadable, multiple: false, require: true, default: "public"
  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :embargo_date, multiple: false, required: false, type: Valkyrie::Types::String.optional
  delegate :human_readable_type, to: :model
  validates :barcode, :box_number, :visibility, presence: true
  validate :barcode_valid?
  validate :drive_barcode_valid?
  validates_with StateValidator
  validates_with MemberValidator
  validates_with RightsStatementValidator
  validates_with EmbargoDateValidator

  def barcode_valid?
    return if Barcode.new(Array.wrap(barcode).first).valid?
    errors.add(:barcode, "has an invalid checkdigit")
  end

  def drive_barcode_valid?
    return if drive_barcode.blank? || Barcode.new(Array.wrap(drive_barcode).first).valid?
    errors.add(:drive_barcode, "has an invalid checkdigit")
  end

  def primary_terms
    [
      :barcode,
      :box_number,
      :shipped_date,
      :received_date,
      :tracking_number,
      :drive_barcode,
      :append_id,
      :embargo_date
    ]
  end

  # Boxes only have metadata, so we may as well preserve it always.
  def preserve?
    true
  end

  # Don't automatically preserve children on save. Children have their own
  # states and will preserve on complete.
  def preserve_children?
    false
  end
end
