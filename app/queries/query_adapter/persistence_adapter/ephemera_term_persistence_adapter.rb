# frozen_string_literal: true
module QueryAdapter
  module PersistenceAdapter
    class EphemeraTermPersistenceAdapter < Base
      private

        def save(label:, tgm_label:, lcsh_label:, uri:, vocabulary:)
          term = EphemeraTerm.new(label: label, tgm_label: tgm_label, lcsh_label: lcsh_label, uri: uri)
          change_set = EphemeraTermChangeSet.new(term)
          change_set.validate(term.attributes)
          change_set.member_of_vocabulary_id = vocabulary.id if vocabulary.present?
          return false unless change_set.sync
          @change_set_persister.save(change_set: change_set)
        end
    end
  end
end
