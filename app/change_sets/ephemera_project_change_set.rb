# frozen_string_literal: true
class EphemeraProjectChangeSet < Valkyrie::ChangeSet
  validates :name, presence: true
  property :name, multiple: false

  def primary_terms
    [
      :name
    ]
  end
end
