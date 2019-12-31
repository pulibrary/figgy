# frozen_string_literal: true
class EphemeraFieldChangeSet < Valkyrie::ChangeSet
  validates :field_name, :member_of_vocabulary_id, presence: true

  include OptimisticLockProperty

  property :field_name, multiple: false, required: true
  property :member_of_vocabulary_id, multiple: false, required: true, type: Valkyrie::Types::ID.optional
  property :favorite_term_ids, multiple: true, required: false, type: Valkyrie::Types::Set.of(Valkyrie::Types::ID.optional)

  validates_with VocabularyValidator

  def primary_terms
    [:field_name, :member_of_vocabulary_id, :favorite_term_ids, :append_id, :optimistic_lock_token]
  end
end
