# frozen_string_literal: true

module Migrations
  class AddCachedParentIdsMigrator
    def self.call
      new.run
    end

    delegate :query_service, to: :change_set_persister
    delegate :resource_factory, to: :query_service
    delegate :orm_class, to: :resource_factory

    def run
      resources = relation.map do |object|
        resource_factory.to_resource(object: object)
      end
      resources.each do |resource|
        if resource.respond_to?(:cached_parent_id)
          change_set = ChangeSet.for(resource)
          change_set_persister.save(change_set: change_set)
        end
      end
    end

    # Rather than make a query that's only used by this migration, just do one
    # inline here.
    def relation
      orm_class.use_cursor
        .exclude(internal_resource: [FileSet, PreservationObject, Tombstone, Event, EphemeraTerm].map(&:to_s))
        .exclude(Sequel[:metadata].pg_jsonb.contains(cached_parent_id: [{}]))
        .lazy
    end

    def change_set_persister
      @change_set_persister ||= ::ChangeSetPersister::Basic.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter,
        handlers: handlers
      )
    end

    # Only do one handler for performance.
    def handlers
      {
        before_save: [
          ChangeSetPersister::CacheParentId
        ]
      }
    end
  end
end
