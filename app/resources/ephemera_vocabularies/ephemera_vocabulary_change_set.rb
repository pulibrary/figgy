# frozen_string_literal: true
class EphemeraVocabularyChangeSet < Valkyrie::ChangeSet
  validates :label, presence: true
  property :label, multiple: false, required: true
  property :uri, multiple: false, required: false, type: ::Types::URI
  property :definition, multiple: false, required: false
  property :member_of_vocabulary_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional

  validates_with VocabularyValidator

  def primary_terms
    [:label, :uri, :definition, :member_of_vocabulary_id]
  end
end
