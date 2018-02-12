# frozen_string_literal: true
class LeastRecentlyUpdatedFileSet
  def self.queries
    [:least_recently_updated_file_set]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def least_recently_updated_file_set
    run_query(query).first
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      internal_resource='FileSet'
      order by updated_at
      limit 1
    SQL
  end

  def run_query(query)
    orm_class.find_by_sql([query]).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
