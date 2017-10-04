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

  def ephemera_vocabularies
    @ephemera_vocabularies ||= CompositeQueryAdapter::EphemeraVocabularyCompositeQueryAdapter.new(query_service: query_service, change_set_persister: change_set_persister)
  end

  def ephemera_terms
    @ephemera_terms ||= CompositeQueryAdapter::EphemeraTermCompositeQueryAdapter.new(query_service: query_service, change_set_persister: change_set_persister)
  end

  def ingest
    vocab = ephemera_vocabularies.find_or_create_by(label: name) if name
    CSV.foreach(file, headers: true) do |obj|
      row = obj.to_h
      category_label = fetch(row, :category)
      category = ephemera_vocabularies.find_or_create_by(label: category_label, vocabulary: vocab) if category_label
      ephemera_terms.find_or_create_by(
        label: fetch(row, :label),
        tgm_label: fetch(row, :tgm_label),
        lcsh_label: fetch(row, :lcsh_label),
        uri: fetch(row, :uri),
        vocabulary: category || vocab
      )

      logger.info row[columns[:label]]
    end
  end

  def fetch(row, key)
    return unless columns[key]
    row[columns[key]]
  end
end
