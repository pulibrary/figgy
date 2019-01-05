# frozen_string_literal: true
class NumismaticIssueChangeSet < ChangeSet
  delegate :human_readable_type, to: :model
  apply_workflow(DraftCompleteWorkflow)

  include VisibilityProperty
  property :artist, multiple: true, required: false, default: []
  property :color, multiple: false, required: false
  property :date_range, multiple: false, required: false
  property :denomination, multiple: false, required: false
  property :description, multiple: false, required: false
  property :edge, multiple: false, required: false
  property :era, multiple: false, required: false
  property :geographic_origin, multiple: false, required: false
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
  property :numismatic_monogram_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :pending_uploads, multiple: true, required: false

  property :start_canvas, required: false
  property :viewing_direction, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"

  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :rights_note, multiple: false, required: false

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :date_range_form_attributes, virtual: true

  validates_with AutoIncrementValidator, property: :issue_number
  validates_with CollectionValidator
  validates_with MemberValidator
  validates_with RightsStatementValidator
  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates :visibility, presence: true
  validate :date_range_validity

  def date_range_form_attributes=(attributes)
    return unless date_range_form.validate(attributes)
    date_range_form.sync
    self.date_range = date_range_form.model
  end

  def date_range_validity
    return if date_range_form.valid?
    errors.add(:date_range_form, "is not valid.")
  end

  def date_range_form
    @date_range_form ||= DynamicChangeSet.new(date_range_value || DateRange.new).tap(&:prepopulate!)
  end

  def date_range_value
    Array.wrap(date_range).first
  end

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
        :master,
        :workshop,
        :series,
        :place,
        :geographic_origin
      ],
      "Obverse" => [
        :obverse_figure,
        :obverse_symbol,
        :obverse_part,
        :obverse_orientation,
        :obverse_figure_description,
        :obverse_figure_relationship,
        :obverse_legend,
        :obverse_attributes
      ],
      "Reverse" => [
        :reverse_figure,
        :reverse_symbol,
        :reverse_part,
        :reverse_orientation,
        :reverse_figure_description,
        :reverse_figure_relationship,
        :reverse_legend,
        :reverse_attributes
      ],
      "Rights and Notes" => [
        :note,
        :member_of_collection_ids,
        :rights_statement,
        :rights_note
      ],
      "Artists and Subjects" => [
        :artist,
        :subject,
        :description,
        :numismatic_monogram_ids
      ]
    }
  end
end
