# frozen_string_literal: true
class CoinChangeSet < ChangeSet
  delegate :human_readable_type, to: :model
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  property :coin_number, multiple: false, required: false
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :holding_location, multiple: false, required: false
  property :counter_stamp, multiple: false, required: false
  property :analysis, multiple: false, required: false
  property :public_note, multiple: true, required: false, default: []
  property :private_note, multiple: true, required: false, default: []
  property :find_date, multiple: false, required: false
  property :find_feature, multiple: false, required: false
  property :find_locus, multiple: false, required: false
  property :find_number, multiple: false, required: false
  property :find_description, multiple: false, required: false
  property :accession_number, multiple: false, required: false
  property :provenance, multiple: true, required: false, default: []
  property :die_axis, multiple: false, required: false
  property :loan, multiple: false, required: false
  property :size, multiple: false, required: false
  property :technique, multiple: false, required: false
  property :weight, multiple: false, required: false
  property :find_place, multiple: false, required: false
  property :replaces, multiple: true, required: false, default: []
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
  validates_with CollectionValidator
  validates_with MemberValidator
  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates :visibility, presence: true

  def primary_terms
    [
      :weight,
      :size,
      :die_axis,
      :technique,
      :counter_stamp,
      :analysis,
      :public_note,
      :private_note,
      :find_place,
      :find_number,
      :find_date,
      :find_locus,
      :find_feature,
      :find_description,
      :holding_location,
      :member_of_collection_ids,
      :accession_number,
      :provenance,
      :loan,
      :append_id,
    ]
  end
end
