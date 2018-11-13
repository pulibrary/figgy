# frozen_string_literal: true
class PlaylistChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  delegate :human_readable_type, to: :resource
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :title, multiple: true, required: true, default: []
  property :read_groups, multiple: true, required: false
  property :file_set_ids, virtual: true, type: Valkyrie::Types::Array.of(Valkyrie::Types::ID)
  property :detached_member_ids, virtual: true, type: Valkyrie::Types::Array.of(Valkyrie::Types::ID)

  validates_with MemberValidator
  validates :visibility, :title, presence: true

  def primary_terms
    [
      :title
    ]
  end
end
