# frozen_string_literal: true
class NumismaticAccession < Resource
  include Valkyrie::Resource::AccessControls

  attribute :accession_number, Valkyrie::Types::Integer
  attribute :account
  attribute :cost
  attribute :date
  attribute :firm
  attribute :items_number, Valkyrie::Types::Integer
  attribute :note
  attribute :numismatic_citation, Valkyrie::Types::Array.of(NumismaticCitation).meta(ordered: true)
  attribute :person
  attribute :private_note
  attribute :thumbnail_id
  attribute :type

  def title
    ["Accession: #{accession_number}"]
  end
end
