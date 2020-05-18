# frozen_string_literal: true
class PagedAllQuery
  def self.queries
    [:paged_all]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def paged_all(limit: 10, offset: 0, from: nil, until_time: nil, only_models: [], collection_slug: nil, marc_only: false)
    connection.transaction(savepoint: true) do
      collections = collections(collection_slug)
      return [] if collection_slug && collections.empty?
      relation = PagedAllBuilder.new(query_service: query_service, limit: limit)

      relation.offset(offset).with_collections(collections).only_models(only_models).from(from).until(until_time)
      relation.only_marc if marc_only

      relation = relation.lazy.map do |object|
        resource_factory.to_resource(object: object)
      end
      # Remove objects with parents - this appears to be faster than a left join
      # filter.
      relation.select do |object|
        Wayfinder.for(object).parents.blank?
      end
    end
  end

  def collections(collection_slug)
    return [] unless collection_slug
    query_service.custom_queries.find_by_property(property: :slug, value: collection_slug)
  end

  class PagedAllBuilder
    attr_reader :query_service, :limit
    attr_writer :relation
    delegate :resource_factory, to: :query_service
    delegate :orm_class, to: :resource_factory
    delegate :lazy, to: :relation
    def initialize(query_service:, limit:)
      @query_service = query_service
      @limit = limit
    end

    def from(from)
      return self unless from
      tap do
        self.relation = relation.where(Sequel[:orm_resources][:updated_at] >= from)
      end
    end

    def until(until_time)
      return self unless until_time
      tap do
        self.relation = relation.where(Sequel[:orm_resources][:updated_at] <= until_time)
      end
    end

    def only_marc
      tap do
        self.relation = relation.exclude(Sequel[:orm_resources][:metadata].pg_jsonb.contains(archival_collection_code: []))
      end
    end

    def offset(offset)
      tap do
        self.relation = relation.offset(offset)
      end
    end

    def with_collections(collections)
      return self unless collections.present?
      tap do
        self.relation = relation.where(Sequel[:orm_resources][:metadata].pg_jsonb.contains(initial_requirements.merge(member_of_collection_ids: collections.map(&:id))))
      end
    end

    def only_models(models)
      return self unless models.present?
      tap do
        self.relation = relation.where(Sequel[:orm_resources][:internal_resource] => Array(models).map(&:to_s))
      end
    end

    def initial_requirements
      { source_metadata_identifier: [], imported_metadata: [{}] }
    end

    def relation
      @relation ||= orm_class.use_cursor.limit(limit).order(Sequel[:orm_resources][:updated_at])
    end
  end
end
