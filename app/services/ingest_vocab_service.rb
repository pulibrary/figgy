# frozen_string_literal: true
require 'csv'

class IngestVocabService
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  attr_reader :file, :name, :columns, :change_set_persister, :logger
  def initialize(change_set_persister, file, name, columns, logger = Logger.new(STDOUT))
    @file = file
    @name = name
    @columns = columns
    @change_set_persister = change_set_persister
    @logger = logger
  end

  def vocab_queries
    @vocab_queries ||= QueryAdapter.new(query_service: query_service, model: EphemeraVocabulary)
  end

  def vocab_persistence
    @vocab_persistence ||= PersistenceAdapter.new(change_set_persister: change_set_persister, model: EphemeraVocabulary)
  end

  def term_queries
    @term_queries ||= QueryAdapter.new(query_service: query_service, model: EphemeraTerm)
  end

  def term_persistence
    @term_persistence ||= PersistenceAdapter.new(change_set_persister: change_set_persister, model: EphemeraTerm)
  end

  def ingest_vocabulary(label:, parent_vocab: nil)
    return unless label
    category = vocab_queries.find_with(FindEphemeraVocabularyByLabel, label: label, parent_vocab: parent_vocab).first
    return category if category.present?
    vocab_persistence.create(label: label) do |change_set|
      change_set.member_of_vocabulary_id = parent_vocab.id if parent_vocab.present?
    end
  end

  def ingest_term(label:, tgm_label:, lcsh_label:, uri:, parent_vocab:)
    term = term_queries.find_with(FindEphemeraTermByLabel, label: label).first
    return term if term.present?
    term_persistence.create(label: label, tgm_label: tgm_label, lcsh_label: lcsh_label, uri: uri) do |change_set|
      change_set.member_of_vocabulary_id = parent_vocab.id if parent_vocab.present?
    end
  end

  def ingest
    vocab = ingest_vocabulary(label: name)
    CSV.foreach(file, headers: true) do |obj|
      row = obj.to_h

      category_label = fetch(row, :category)
      category = ingest_vocabulary(label: category_label, parent_vocab: vocab)

      ingest_term(
        label: fetch(row, :label),
        tgm_label: fetch(row, :tgm_label),
        lcsh_label: fetch(row, :lcsh_label),
        uri: fetch(row, :uri),
        parent_vocab: category || vocab
      )

      logger.info row[columns[:label]]
    end
  end

  def fetch(row, key)
    return unless columns[key]
    row[columns[key]]
  end
end
