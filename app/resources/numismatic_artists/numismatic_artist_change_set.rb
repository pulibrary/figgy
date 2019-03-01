# frozen_string_literal: true
class NumismaticArtistChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model

  property :person, multiple: false, required: false
  property :signature, multiple: false, required: false
  property :role, multiple: false, required: false
  property :side, multiple: false, required: false

  # Virtual Attributes
  property :artist_parent_id, virtual: true, multiple: false, required: false

  def primary_terms
    [
      :person,
      :signature,
      :role,
      :side,
      :artist_parent_id
    ]
  end
end
