# frozen_string_literal: true
class NumismaticAccession < Resource
  include Valkyrie::Resource::AccessControls

  # resources linked by ID
  attribute :firm_id
  attribute :person_id

  # nested resources
  attribute :numismatic_citation, Valkyrie::Types::Array.of(NumismaticCitation).meta(ordered: true)

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

  def title
    ["Accession: #{accession_number}"]
  end
end
