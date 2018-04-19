# frozen_string_literal: true
class EphemeraFieldChangeSet < Valkyrie::ChangeSet
  validates :field_name, :member_of_vocabulary_id, presence: true
  property :field_name, multiple: false, required: true
  property :member_of_vocabulary_id, multiple: false, required: true, type: Valkyrie::Types::ID.optional

  validates_with VocabularyValidator

  def primary_terms
    [:field_name, :member_of_vocabulary_id, :append_id]
  end
end
