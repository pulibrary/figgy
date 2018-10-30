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
      :references
    ]
  end
end
