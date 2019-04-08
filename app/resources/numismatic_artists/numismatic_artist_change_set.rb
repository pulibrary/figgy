# frozen_string_literal: true
class NumismaticArtistChangeSet < ChangeSet
  delegate :human_readable_type, to: :model

  property :person, multiple: false, required: false
  property :signature, multiple: false, required: false
  property :role, multiple: false, required: false
  property :side, multiple: false, required: false

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
      :person,
      :signature,
      :role,
      :side
    ]
  end
end
