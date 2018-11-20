# frozen_string_literal: true
class NumismaticAccession < Resource
  include Valkyrie::Resource::AccessControls

  attribute :accession_number, Valkyrie::Types::Int
  attribute :number_in_accession, Valkyrie::Types::Int
  attribute :date
  attribute :items_number, Valkyrie::Types::Int
  attribute :type
  attribute :cost
  attribute :account
  attribute :person
  attribute :firm
  attribute :note
  attribute :private_note
  attribute :thumbnail_id

  def title
    ["Accession: #{accession_number}"]
  end
end
