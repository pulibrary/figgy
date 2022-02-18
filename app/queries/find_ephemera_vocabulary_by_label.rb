# frozen_string_literal: true

class FindEphemeraVocabularyByLabel
  def self.queries
    [:find_ephemera_vocabulary_by_label]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_ephemera_vocabulary_by_label(label:, parent_vocab_label: nil)
    if parent_vocab_label
      internal_array = {label: Array.wrap(parent_vocab_label)}.to_json
      parent_vocab = run_query(query, EphemeraVocabulary.to_s, internal_array).first
      internal_array = {label: Array.wrap(label), member_of_vocabulary_id: Array.wrap(parent_vocab.id)}.to_json
      run_query(query, EphemeraVocabulary.to_s, internal_array).first
    else
      internal_array = {label: Array.wrap(label)}.to_json
    end
    run_query(query, EphemeraVocabulary.to_s, internal_array).first
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      internal_resource = ? AND
      metadata @> ?
    SQL
  end
end
