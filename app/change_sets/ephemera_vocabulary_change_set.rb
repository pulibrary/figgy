# frozen_string_literal: true
class EphemeraVocabularyChangeSet < Valkyrie::ChangeSet
  validates :label, :value, presence: true
  property :label, multiple: false, required: true
  property :value, multiple: false, required: true
  property :definition, multiple: false, required: false
  property :member_of_vocabulary_id, multiple: false, required: false, type: Valkyrie::Types::ID

  def primary_terms
    [:label, :value, :definition, :member_of_vocabulary_id]
  end
end
