# frozen_string_literal: true
class FileSetsSortedByUpdated
  def self.queries
    [:file_sets_sorted_by_updated]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def file_sets_sorted_by_updated(sort: 'asc', limit: 50)
    run_query("#{query} #{order(sort)} #{number(limit)}")
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      internal_resource='FileSet'
    SQL
  end

  def order(sort)
    "order by updated_at #{sort}"
  end

  def number(limit)
    "limit #{limit}"
  end

  def run_query(query)
    orm_class.find_by_sql([query]).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
