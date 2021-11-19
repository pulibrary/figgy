# frozen_string_literal: true
module Numismatics
  class Accession < Resource
    include Valkyrie::Resource::AccessControls

    # resources linked by ID
    attribute :firm_id
    attribute :person_id

    # nested resources
    attribute :numismatic_citation, Valkyrie::Types::Array.of(Numismatics::Citation).meta(ordered: true)

    # descriptive metadata
    attribute :accession_number, Valkyrie::Types::Integer
    attribute :account
    attribute :cost
    attribute :date
    attribute :items_number, Valkyrie::Types::Integer
    attribute :note
    attribute :private_note
    attribute :replaces
    attribute :type
    attribute :depositor
  end
end
