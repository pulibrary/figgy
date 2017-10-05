# frozen_string_literal: true
class FindEphemeraTermByLabel
  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_ephemera_term_by_label(label:, vocab_label: nil)
    if vocab_label
      vocab = run_query(query, EphemeraVocabulary.to_s, vocab_label).first
      internal_array = "[{\"id\": \"#{vocab.id}\"}]"
      run_query(query_with_vocab_id, EphemeraTerm.to_s, label, internal_array).first
    else
      run_query(query, EphemeraTerm.to_s, label).first
    end
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      internal_resource = ? AND
      metadata->>'label' = ?
    SQL
  end

  def query_with_vocab_id
    <<-SQL
      select * from orm_resources WHERE
      internal_resource = ? AND
      metadata->>'label' = ? AND
      metadata->'member_of_vocabulary_id' @> ?
    SQL
  end

  def run_query(query, *args)
    orm_class.find_by_sql(([query] + args)).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
