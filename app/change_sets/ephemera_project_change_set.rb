# frozen_string_literal: true
class EphemeraProjectChangeSet < Valkyrie::ChangeSet
  validates :name, presence: true
  property :name, multiple: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)

  def primary_terms
    [:name]
  end
end
