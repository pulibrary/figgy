# frozen_string_literal: true

class VocabularyService
  attr_accessor :change_set_persister, :persist_if_not_found, :imported_vocabulary
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, :persister, to: :metadata_adapter

  def initialize(change_set_persister:, persist_if_not_found: true)
    @change_set_persister = change_set_persister
    @persist_if_not_found = persist_if_not_found
  end

  class EphemeraVocabularyService < VocabularyService
    def initialize(change_set_persister:, persist_if_not_found: true)
      super(change_set_persister: change_set_persister,
            persist_if_not_found: persist_if_not_found)
    end

    def imported_vocabulary
      @imported_vocabulary ||= find_vocabulary_by(label: "Imported Terms")
    end

    def find_vocabulary_by(label:, vocabulary_id: nil)
      vocab = query_service.custom_queries.find_ephemera_vocabulary_by_label(label: label)
      return vocab if vocab
      persister.save(resource: EphemeraVocabulary.new(label: label, member_of_vocabulary_id: vocabulary_id)) if persist_if_not_found
    end

    def find_term(label: nil, code: nil, vocab: nil)
      term = query_service.custom_queries.find_ephemera_term_by_label(label: label,
                                                                      code: code,
                                                                      parent_vocab_label: vocab)
      return term.id if term
      persister.save(resource: EphemeraTerm.new(label: label, member_of_vocabulary_id: imported_vocabulary.id)) if persist_if_not_found
    end

    def find_subject_by(category:, topic:)
      begin
        subject = query_service.custom_queries.find_ephemera_term_by_label(label: topic, parent_vocab_label: category)
      rescue
        subject = nil
      end
      return subject if subject
      vocabulary = find_vocabulary_by(label: category, vocabulary_id: imported_vocabulary.id)
      persister.save(resource: EphemeraTerm.new(label: topic, member_of_vocabulary_id: vocabulary.id)) if vocabulary && persist_if_not_found
    end
  end
end
