# frozen_string_literal: true
class PlaylistChangeSet < ChangeSet
  delegate :human_readable_type, to: :resource
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :label, multiple: true, required: true, default: []
  property :read_groups, multiple: true, required: false

  validates_with MemberValidator
  validates :visibility, :label, presence: true

  def primary_terms
    [
      :label
    ]
  end
end
