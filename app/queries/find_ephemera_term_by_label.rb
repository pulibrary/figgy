# frozen_string_literal: true
class FindEphemeraTermByLabel
  def self.queries
    [:find_ephemera_term_by_label]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_ephemera_term_by_label(label:, parent_vocab_label: nil)
    if parent_vocab_label
      internal_array = { label: Array.wrap(parent_vocab_label) }.to_json
      parent_vocab = run_query(query, EphemeraVocabulary.to_s, internal_array).first
      internal_array = { label: Array.wrap(label), member_of_vocabulary_id: Array.wrap(parent_vocab.id) }.to_json
    else
      internal_array = { label: Array.wrap(label) }.to_json
    end
    run_query(query, EphemeraTerm.to_s, internal_array).first
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      internal_resource = ? AND
      metadata @> ?
    SQL
  end

  def run_query(query, *args)
    orm_class.find_by_sql(([query] + args)).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
