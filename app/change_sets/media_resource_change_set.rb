# frozen_string_literal: true
class MediaResourceChangeSet < Valhalla::ChangeSet
  apply_workflow(WorkflowRegistry.workflow_for(MediaResource))
  delegate :human_readable_type, to: :resource

  include VisibilityProperty
  property :title, multiple: true, required: true, default: []
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false
  property :depositor, multiple: false, require: false

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false

  validates_with StateValidator
  validates :visibility, :rights_statement, presence: true

  def primary_terms
    [
      :title,
      :rights_statement,
      :rights_note,
      :local_identifier,
      :member_of_collection_ids,
      :append_id
    ]
  end
end
