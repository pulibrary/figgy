# frozen_string_literal: true
module QueryAdapter
  module PersistenceAdapter
    class EphemeraVocabularyPersistenceAdapter < Base
      private

        def save(label:, vocabulary: nil)
          v = EphemeraVocabulary.new(label: label)
          change_set = EphemeraVocabularyChangeSet.new(v)
          change_set.validate(v.attributes)
          change_set.member_of_vocabulary_id = vocabulary.id if vocabulary.present?
          return false unless change_set.sync
          @change_set_persister.save(change_set: change_set)
        end
    end
  end
end
