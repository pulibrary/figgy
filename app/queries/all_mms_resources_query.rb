# frozen_string_literal: true
class AllMmsResourcesQuery
  def self.queries
    [:all_mms_resources, :mms_title_resources]
  end

  attr_reader :query_service
  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def all_mms_resources(created_at: nil)
    relation = orm_class.use_cursor
    relation = relation.exclude(internal_resource: [FileSet, PreservationObject, DeletionMarker, Event, EphemeraTerm].map(&:to_s))
    relation = relation.where(created_at: created_at) if created_at
    relation = relation.where(Sequel.lit("metadata ->> 'source_metadata_identifier' ~ '99[0-9]+6421'"))
    relation.map do |object|
      resource_factory.to_resource(object: object)
    end
  end

  def mms_title_resources(created_at: nil)
    relation = orm_class.use_cursor
    relation = relation.exclude(internal_resource: [FileSet, PreservationObject, DeletionMarker, Event, EphemeraTerm].map(&:to_s))
    relation = relation.where(created_at: created_at) if created_at
    relation = relation.where(Sequel.lit("metadata ->> 'title' ~ '99[0-9]+6421'"))
    relation.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
