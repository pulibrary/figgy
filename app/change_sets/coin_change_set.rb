# frozen_string_literal: true
class CoinChangeSet < ChangeSet
  delegate :human_readable_type, to: :model
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  property :department, multiple: false, required: false
  property :size, multiple: false, required: false
  property :die_axis, multiple: false, required: false
  property :weight, multiple: false, required: false
  property :references, multiple: false, required: false
  property :accession, multiple: false, required: false
  property :analysis, multiple: false, required: false
  property :counter_stamp, multiple: false, required: false
  property :find, multiple: false, required: false
  property :find_date, multiple: false, required: false
  property :holding_location, multiple: false, required: false
  property :loan, multiple: false, required: false
  property :object_type, multiple: false, required: false
  property :place, multiple: false, required: false
  property :private_note, multiple: true, required: false
  property :provenance, multiple: true, required: false
  property :technique, multiple: false, required: false

  property :read_groups, multiple: true, required: false
  property :depositor, multiple: false, required: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with MemberValidator
  validates :visibility, presence: true

  def primary_terms
    [
      :department,
      :size,
      :die_axis,
      :weight,
      :donor,
      :deposit_of,
      :seller,
      :references,
      :accession,
      :analysis,
      :counter_stamp,
      :find,
      :find_date,
      :holding_location,
      :loan,
      :object_type,
      :place,
      :private_note,
      :provenance,
      :references,
      :size,
      :technique,
      :weight
    ]
  end
end
