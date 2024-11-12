# frozen_string_literal: true
module Numismatics
  class CoinChangeSet < ChangeSet
    delegate :human_readable_type, to: :model
    apply_workflow(DraftCompleteWorkflow)
    enable_claiming

    include VisibilityProperty
    collection :numismatic_citation, multiple: true, required: false, form: Numismatics::CitationChangeSet, populator: :populate_nested_collection, default: []
    collection :loan, multiple: true, required: false, form: Numismatics::LoanChangeSet, populator: :populate_nested_collection, default: []
    collection :provenance, multiple: true, required: false, form: Numismatics::ProvenanceChangeSet, populator: :populate_nested_collection, default: []
    property :coin_number, multiple: false, required: false
    property :number_in_accession, multiple: false, required: false
    property :counter_stamp, multiple: false, required: false
    property :analysis, multiple: false, required: false
    property :public_note, multiple: true, required: false, default: []
    property :private_note, multiple: true, required: false, default: []
    property :find_date, multiple: false, required: false
    property :find_feature, multiple: false, required: false
    property :find_locus, multiple: false, required: false
    property :find_number, multiple: false, required: false
    property :find_description, multiple: false, required: false
    property :die_axis, multiple: false, required: false
    property :size, multiple: false, required: false
    property :technique, multiple: false, required: false
    property :weight, multiple: false, required: false
    property :numismatic_collection, multiple: false, required: false
    property :replaces, multiple: true, required: false, default: []
    property :depositor, multiple: false, required: false
    property :read_groups, multiple: true, required: false
    property :rights_statement, multiple: false, required: true, default: RightsStatements.copyright_not_evaluated, type: ::Types::URI
    property :append_id, virtual: true, multiple: false, required: true
    property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional

    # Resources linked by reference
    property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :numismatic_accession_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :find_place_id, multiple: false, required: false, type: Valkyrie::Types::ID

    # Properties for IIIF
    property :start_canvas, required: false
    property :viewing_direction, required: false
    property :viewing_hint, multiple: false, required: false, default: "individuals"
    property :downloadable, multiple: false, require: true, default: "public"

    property :pdf_type, multiple: false, required: false, default: "color"
    property :file_metadata, multiple: true, required: false, default: []

    # Virtual Attributes
    property :files, virtual: true, multiple: true, required: false
    property :pending_uploads, multiple: true, required: false

    # validates_with ParentValidator
    validates_with AutoIncrementValidator, property: :coin_number
    validates_with CollectionValidator
    validates_with MemberValidator
    validates_with StateValidator
    validates_with ViewingDirectionValidator
    validates_with ViewingHintValidator
    validates_with RightsStatementValidator
    validates_with ProcessedValidator
    validates :visibility, presence: true

    def primary_terms
      {
        "" => [
          :weight,
          :size,
          :die_axis,
          :technique,
          :counter_stamp,
          :analysis,
          :public_note,
          :private_note,
          :find_place_id,
          :find_number,
          :find_date,
          :find_locus,
          :find_feature,
          :find_description,
          :numismatic_collection,
          :member_of_collection_ids
        ],
        "Accession" => [
          :numismatic_accession_id,
          :number_in_accession
        ],
        "Citation" => [
          :numismatic_citation
        ],
        "Provenance" => [
          :provenance
        ],
        "Loans and Exhibits" => [
          :loan
        ],
        "Numismatic Issue" => [
          :append_id
        ]
      }
    end

    def build_numismatic_citation
      schema["numismatic_citation"][:nested].new(model_type_for(property: :numismatic_citation)[[{}]].first)
    end

    def build_loan
      schema["loan"][:nested].new(model_type_for(property: :loan)[[{}]].first)
    end

    def build_provenance
      schema["provenance"][:nested].new(model_type_for(property: :provenance)[[{}]].first)
    end
  end
end
