# frozen_string_literal: true
class NumismaticAccessionChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model

  property :date, multiple: false, required: false
  property :person, multiple: false, required: false
  property :firm, multiple: false, required: false
  property :accession_number, multiple: false, required: false
  property :type, multiple: false, required: false
  property :cost, multiple: false, required: false
  property :account, multiple: false, required: false
  property :note, multiple: false, required: false
  property :private_note, multiple: false, required: false

  validates_with AutoIncrementValidator, property: :accession_number

  def primary_terms
    [
      :date,
      :person,
      :firm,
      :type,
      :cost,
      :account,
      :note,
      :private_note
    ]
  end
end
