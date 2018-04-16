# frozen_string_literal: true
class FindUnrelated
  def self.queries
    [:find_unrelated]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_unrelated_query(id:, model:)
    <<-SQL
      SELECT resource.* FROM orm_resources AS resource
      WHERE resource.id != '#{id}'::uuid AND resource.internal_resource='#{model}';
    SQL
  end

  # @param id [Valkyrie::ID, String]
  # @param model [Class, String]
  def find_unrelated(id:, model:)
    query_service.run_query(find_unrelated_query(id: id, model: model))
  end

  def id_type
    @id_type ||= orm_class.columns_hash["id"].type
  end
end
