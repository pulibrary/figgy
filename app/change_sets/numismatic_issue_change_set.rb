# frozen_string_literal: true
class NumismaticIssueChangeSet < ChangeSet
  delegate :human_readable_type, to: :model
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  property :object_type, multiple: false, required: false
  property :denomination, multiple: false, required: false
  property :metal, multiple: false, required: false
  property :geographic_origin, multiple: false, required: false
  property :workshop, multiple: false, required: false
  property :ruler, multiple: false, required: false
  property :date_range, multiple: false, required: false
  property :obverse_type, multiple: false, required: false
  property :obverse_legend, multiple: false, required: false
  property :obverse_attributes, multiple: true, required: false
  property :reverse_type, multiple: false, required: false
  property :reverse_legend, multiple: false, required: false
  property :reverse_attributes, multiple: true, required: false
  property :master, multiple: false, required: false
  property :description, multiple: false, required: false
  property :references, multiple: true, required: false

  property :read_groups, multiple: true, required: false
  property :depositor, multiple: false, required: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)

  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false

  validates_with MemberValidator
  validates_with RightsStatementValidator
  validates :visibility, presence: true

  def primary_terms
    [
      :object_type,
      :denomination,
      :metal,
      :geographic_origin,
      :workshop,
      :ruler,
      :date_range,
      :obverse_type,
      :obverse_legend,
      :obverse_attributes,
      :reverse_type,
      :reverse_legend,
      :reverse_attributes,
      :master,
      :description,
      :references,
      :rights_statement,
      :rights_note
    ]
  end
end
