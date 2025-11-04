# frozen_string_literal: true

module Migrations
  class AddPublishedAtMigrator
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
        next unless resource.respond_to?(:published_at)
        decorator = resource.decorate
        next unless decorator.respond_to?(:published_state?) && decorator.published_state?
        change_set = ChangeSet.for(resource)
        next unless change_set.respond_to?(:published_at)
        change_set.resource.published_at = resource.updated_at
        change_set_persister.save(change_set: change_set)
      rescue
        next
      end
    end

    # Rather than make a query that's only used by this migration, just do one
    # inline here.
    def relation
      orm_class.use_cursor(skip_transaction: true)
               .exclude(internal_resource: [FileSet, PreservationObject, DeletionMarker, Event, EphemeraTerm].map(&:to_s))
               .where(Sequel.lit("metadata->'published_at' IS NULL"))
               .lazy
    end

    def change_set_persister
      @change_set_persister ||= ::ChangeSetPersister::Basic.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter,
        handlers: handlers
      )
    end

    # Only use preservation handler for performance.
    def handlers
      {
        after_save_commit: [
          ChangeSetPersister::PreserveResource
        ]
      }
    end
  end
end
