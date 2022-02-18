# frozen_string_literal: true

class FindEphemeraTermByLabel
  def self.queries
    [:find_ephemera_term_by_label]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_ephemera_term_by_label(label: nil, code: nil, parent_vocab_label: nil)
    raise(ArgumentError, "Either label or code must be specified") unless label || code
    if parent_vocab_label
      internal_array = {label: Array.wrap(parent_vocab_label)}.to_json
      parent_vocab = run_query(query, EphemeraVocabulary.to_s, internal_array).first
      internal_array = {member_of_vocabulary_id: Array.wrap(parent_vocab.id)}
    else
      internal_array = {}
    end
    internal_array[:code] = Array.wrap(code) if code
    internal_array[:label] = Array.wrap(label) if label
    run_query(query, EphemeraTerm.to_s, internal_array.to_json).first
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      internal_resource = ? AND
      metadata @> ?
    SQL
  end
end
