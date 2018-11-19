# frozen_string_literal: true
class CoinChangeSet < ChangeSet
  delegate :human_readable_type, to: :model
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  property :accession_number, multiple: false, required: false
  property :analysis, multiple: false, required: false
  property :coin_number, multiple: false, required: false
  property :counter_stamp, multiple: false, required: false
  property :department, multiple: false, required: false
  property :die_axis, multiple: false, required: false
  property :find_date, multiple: false, required: false
  property :find_description, multiple: false, required: false
  property :find_feature, multiple: false, required: false
  property :find_locus, multiple: false, required: false
  property :find_number, multiple: false, required: false
  property :find_place, multiple: false, required: false
  property :holding_location, multiple: false, required: false
  property :loan, multiple: false, required: false
  property :object_type, multiple: false, required: false
  property :place, multiple: false, required: false
  property :private_note, multiple: true, required: false, default: []
  property :provenance, multiple: true, required: false, default: []
  property :replaces, multiple: true, required: false, default: []
  property :size, multiple: false, required: false
  property :technique, multiple: false, required: false
  property :weight, multiple: false, required: false

  property :depositor, multiple: false, required: false
  property :numismatic_citation_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false

  property :start_canvas, required: false
  property :viewing_direction, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with AutoIncrementValidator, property: :coin_number
  validates_with MemberValidator
  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates :visibility, presence: true

  def primary_terms
    [
      :accession_number,
      :analysis,
      :append_id,
      :counter_stamp,
      :department,
      :die_axis,
      :find_date,
      :find_description,
      :find_feature,
      :find_locus,
      :find_number,
      :find_place,
      :holding_location,
      :loan,
      :object_type,
      :place,
      :private_note,
      :provenance,
      :size,
      :technique,
      :weight
    ]
  end
end
