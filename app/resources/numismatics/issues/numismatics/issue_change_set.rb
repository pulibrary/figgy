# frozen_string_literal: true
module Numismatics
  class IssueChangeSet < ChangeSet
    delegate :human_readable_type, to: :model
    apply_workflow(DraftCompleteWorkflow)
    enable_claiming

    include VisibilityProperty
    collection :numismatic_artist, multiple: true, required: false, form: Numismatics::ArtistChangeSet, populator: :populate_nested_collection, default: []
    collection :numismatic_citation, multiple: true, required: false, form: Numismatics::CitationChangeSet, populator: :populate_nested_collection, default: []
    collection :numismatic_note, multiple: true, required: false, form: Numismatics::NoteChangeSet, populator: :populate_nested_collection, default: []
    collection :numismatic_subject, multiple: true, required: false, form: Numismatics::SubjectChangeSet, populator: :populate_nested_collection, default: []
    collection :obverse_attribute, multiple: true, required: false, form: Numismatics::AttributeChangeSet, populator: :populate_nested_collection, default: []
    collection :reverse_attribute, multiple: true, required: false, form: Numismatics::AttributeChangeSet, populator: :populate_nested_collection, default: []
    property :earliest_date, multiple: false, required: false
    property :latest_date, multiple: false, required: false
    property :color, multiple: false, required: false
    property :denomination, multiple: false, required: false
    property :edge, multiple: false, required: false
    property :era, multiple: false, required: false
    property :issue_number, multiple: false, required: false
    property :metal, multiple: false, required: false
    property :object_date, multiple: false, required: false
    property :object_type, multiple: false, required: false
    property :obverse_figure, multiple: false, required: false
    property :obverse_figure_relationship, multiple: false, required: false
    property :obverse_figure_description, multiple: false, required: false
    property :obverse_legend, multiple: false, required: false
    property :obverse_orientation, multiple: false, required: false
    property :obverse_part, multiple: false, required: false
    property :obverse_symbol, multiple: false, required: false
    property :replaces, multiple: true, required: false, default: []
    property :reverse_figure, multiple: false, required: false
    property :reverse_figure_description, multiple: false, required: false
    property :reverse_figure_relationship, multiple: false, required: false
    property :reverse_legend, multiple: false, required: false
    property :reverse_orientation, multiple: false, required: false
    property :reverse_part, multiple: false, required: false
    property :reverse_symbol, multiple: false, required: false
    property :series, multiple: false, required: false
    property :shape, multiple: false, required: false
    property :workshop, multiple: false, required: false

    property :read_groups, multiple: true, required: false
    property :depositor, multiple: false, required: false
    property :master_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :numismatic_place_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :ruler_id, multiple: true, required: false, type: Valkyrie::Types::ID
    property :pending_uploads, multiple: true, required: false

    property :start_canvas, required: false
    property :viewing_direction, required: false
    property :viewing_hint, multiple: false, required: false, default: "individuals"

    property :downloadable, multiple: false, require: true, default: "public"
    property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
    property :rights_note, multiple: false, required: false
    property :state, multiple: false, required: true, default: "complete"

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
    validates :earliest_date, :latest_date, year: true

    def primary_terms
      {
        "" => [
          :object_type,
          :denomination,
          :metal,
          :shape,
          :color,
          :edge,
          [
            :earliest_date,
            :latest_date
          ],
          [
            :era,
            :object_date
          ],
          :ruler_id,
          :numismatic_place_id,
          :master_id,
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
          :obverse_legend
        ],
        "Obverse Attributes" => [
          :obverse_attribute
        ],
        "Reverse" => [
          :reverse_figure,
          :reverse_part,
          :reverse_orientation,
          :reverse_figure_description,
          :reverse_figure_relationship,
          :reverse_symbol,
          :reverse_legend
        ],
        "Reverse Attributes" => [
          :reverse_attribute
        ],
        "Artist" => [
          :numismatic_artist
        ],
        "Citation" => [
          :numismatic_citation
        ],
        "Note" => [
          :numismatic_note
        ],
        "Subject" => [
          :numismatic_subject
        ]
      }
    end

    def build_numismatic_artist
      schema["numismatic_artist"][:nested].new(model_type_for(property: :numismatic_artist)[[{}]].first)
    end

    def build_numismatic_citation
      schema["numismatic_citation"][:nested].new(model_type_for(property: :numismatic_citation)[[{}]].first)
    end

    def build_numismatic_note
      schema["numismatic_note"][:nested].new(model_type_for(property: :numismatic_note)[[{}]].first)
    end

    def build_numismatic_subject
      schema["numismatic_subject"][:nested].new(model_type_for(property: :numismatic_subject)[[{}]].first)
    end

    def build_obverse_attribute
      schema["obverse_attribute"][:nested].new(model_type_for(property: :obverse_attribute)[[{}]].first)
    end

    def build_reverse_attribute
      schema["reverse_attribute"][:nested].new(model_type_for(property: :reverse_attribute)[[{}]].first)
    end
  end
end
