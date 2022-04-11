# frozen_string_literal: true
module Numismatics
  class AccessionChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    collection :numismatic_citation, multiple: true, required: false, form: Numismatics::CitationChangeSet, populator: :populate_nested_collection, default: []
    property :accession_number, multiple: false, required: false
    property :account, multiple: false, required: false
    property :cost, multiple: false, required: false
    property :date, multiple: false, required: false
    property :firm_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :items_number, multiple: false, required: false
    property :note, multiple: false, required: false
    property :person_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :private_note, multiple: false, required: false
    property :replaces, multiple: true, required: false, default: []
    property :type, multiple: false, required: false
    property :depositor, multiple: false, required: false

    validates_with AutoIncrementValidator, property: :accession_number

    # rubocop:disable Metrics/MethodLength
    def primary_terms
      {
        "" => [
          :date,
          :items_number,
          :type,
          :cost,
          :account,
          :person_id,
          :firm_id,
          :note,
          :private_note
        ],
        "Citation" => [
          :numismatic_citation
        ]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def build_numismatic_citation
      schema["numismatic_citation"][:nested].new(model_type_for(property: :numismatic_citation)[[{}]].first)
    end
  end
end
