# frozen_string_literal: true
class NumismaticCitationChangeSet < ChangeSet
  delegate :human_readable_type, to: :model

  property :part, multiple: false, required: false
  property :number, multiple: false, required: false
  property :numismatic_reference_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional

  # Virtual Attributes
  property :_destroy, virtual: true

  def new_record?
    false
  end

  def marked_for_destruction?
    false
  end

  def primary_terms
    [
      :part,
      :number,
      :numismatic_reference_id
    ]
  end
end
