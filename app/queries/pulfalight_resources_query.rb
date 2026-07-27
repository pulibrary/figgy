class PulfalightResourcesQuery
  def self.queries
    [:pulfalight_resources]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def pulfalight_resources(collection:, fields: nil)
    relation = orm_class.use_cursor
    relation = relation.exclude(internal_resource: [FileSet, PreservationObject, DeletionMarker, Event, EphemeraTerm].map(&:to_s))
    relation = relation.where(Sequel[:metadata].pg_jsonb.contains(archival_collection_code: [collection]))
    if fields
      relation.select(*fields)
    else
      relation.map do |object|
        resource_factory.to_resource(object: object)
      end
    end
  end
end
