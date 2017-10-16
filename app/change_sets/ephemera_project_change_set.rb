# frozen_string_literal: true
class EphemeraProjectChangeSet < Valkyrie::ChangeSet
  validates :title, presence: true
  property :title, multiple: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :slug, multiple: false, required: false

  def primary_terms
    [:title, :slug]
  end
end
