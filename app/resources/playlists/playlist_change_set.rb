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
  property :auth_token, multiple: false, require: false

  property :downloadable, multiple: false, require: true, default: "none"
  property :file_set_ids, virtual: true, type: Valkyrie::Types::Array.of(Valkyrie::Types::ID)
  property :mint_auth_token, virtual: true, multiple: false, type: Valkyrie::Types::Array.of(Valkyrie::Types::Bool), default: false
  property :part_of, multiple: true, required: false, default: []
  property :logical_structure, multiple: true, required: false, type: Types::Strict::Array.of(Structure), default: [Structure.new(label: "Logical", nodes: [])]

  validates_with MemberValidator
  validates_with StateValidator
  validates :visibility, :title, presence: true

  def primary_terms
    [
      :title,
      :part_of,
      :downloadable
    ]
  end
end
