# frozen_string_literal: true
class NumismaticIssueChangeSet < ChangeSet
  delegate :human_readable_type, to: :model
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  include DateRangeProperty
  property :color, multiple: false, required: false
  property :denomination, multiple: false, required: false
  property :edge, multiple: false, required: false
  property :era, multiple: false, required: false
  property :issue_number, multiple: false, required: false
  property :master, multiple: false, required: false
  property :metal, multiple: false, required: false
  property :note, multiple: true, required: false, default: []
  property :object_date, multiple: false, required: false
  property :object_type, multiple: false, required: false
  property :obverse_attributes, multiple: true, required: false, default: []
  property :obverse_figure, multiple: false, required: false
  property :obverse_figure_relationship, multiple: false, required: false
  property :obverse_figure_description, multiple: false, required: false
  property :obverse_legend, multiple: false, required: false
  property :obverse_orientation, multiple: false, required: false
  property :obverse_part, multiple: false, required: false
  property :obverse_symbol, multiple: false, required: false
  property :place, multiple: false, required: false, default: []
  property :replaces, multiple: true, required: false, default: []
  property :reverse_attributes, multiple: true, required: false, default: []
  property :reverse_figure, multiple: false, required: false
  property :reverse_figure_description, multiple: false, required: false
  property :reverse_figure_relationship, multiple: false, required: false
  property :reverse_legend, multiple: false, required: false
  property :reverse_orientation, multiple: false, required: false
  property :reverse_part, multiple: false, required: false
  property :reverse_symbol, multiple: false, required: false
  property :ruler, multiple: false, required: false
  property :series, multiple: false, required: false
  property :shape, multiple: false, required: false
  property :subject, multiple: true, required: false, default: []
  property :workshop, multiple: false, required: false

  property :read_groups, multiple: true, required: false
  property :depositor, multiple: false, required: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :numismatic_citation_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :numismatic_artist_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :numismatic_monogram_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :pending_uploads, multiple: true, required: false

  property :start_canvas, required: false
  property :viewing_direction, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"

  property :downloadable, multiple: false, require: true, default: "public"
  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :rights_note, multiple: false, required: false

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false

  validates_with AutoIncrementValidator, property: :issue_number
  validates_with CollectionValidator
  validates_with MemberValidator
  validates_with RightsStatementValidator
  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates :visibility, presence: true

  def primary_terms
    {
      "" => [
        :object_type,
        :denomination,
        :metal,
        :shape,
        :color,
        :edge,
        :object_date,
        :date_range_form,
        :era,
        :ruler,
        :place,
        :master,
        :workshop,
        :series
      ],
      "Obverse" => [
        :obverse_figure,
        :obverse_part,
        :obverse_orientation,
        :obverse_figure_description,
        :obverse_figure_relationship,
        :obverse_symbol,
        :obverse_attributes,
        :obverse_legend
      ],
      "Reverse" => [
        :reverse_figure,
        :reverse_part,
        :reverse_orientation,
        :reverse_figure_description,
        :reverse_figure_relationship,
        :reverse_symbol,
        :reverse_attributes,
        :reverse_legend
      ],
      "Rights and Notes" => [
        :note,
        :member_of_collection_ids,
        :downloadable,
        :rights_statement,
        :rights_note
      ],
      "Artists and Subjects" => [
        :subject,
        :numismatic_monogram_ids
      ]
    }
  end
end
