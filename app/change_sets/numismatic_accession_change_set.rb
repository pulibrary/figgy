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

  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)

  validates_with AutoIncrementValidator, property: :accession_number
  validates_with MemberValidator

  def primary_terms
    [
      :date,
      :person,
      :firm,
      :accession_number,
      :type,
      :cost,
      :account,
      :note,
      :private_note
    ]
  end
end
