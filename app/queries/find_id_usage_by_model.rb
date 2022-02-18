# frozen_string_literal: true

class FindIdUsageByModel
  def self.queries
    [:find_id_usage_by_model]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :resource_factory, to: :query_service
  delegate :connection, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_id_usage_by_model(model:, id:)
    output = connection[query, model.to_s, [id].to_json].to_a
    output_hash = massage_output(output)
    return [] if output_hash.keys.empty?
    objects = query_service.find_many_by_ids(ids: output_hash.keys)
    objects.map do |object|
      {object => output_hash[object.id.to_s]}
    end.reduce(&:merge)
  end

  def massage_output(output)
    output.group_by { |hsh| hsh[:id] }.map { |k, v| [k, v.flat_map { |x| x[:key].to_sym }] }.to_h
  end

  def query
    <<-SQL
      select id, key from orm_resources, jsonb_each(metadata) WHERE
        internal_resource = ? AND
        value @> ?
    SQL
  end
end
