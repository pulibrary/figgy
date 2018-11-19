# frozen_string_literal: true
class NumismaticAccession < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array

  attribute :date
  attribute :person
  attribute :firm
  attribute :accession_number, Valkyrie::Types::Int
  attribute :type
  attribute :cost
  attribute :account
  attribute :note
  attribute :private_note
  attribute :thumbnail_id

  def title
    ["Accession: #{accession_number}"]
  end
end
