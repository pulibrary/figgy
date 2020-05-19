# frozen_string_literal: true

module Migrations
  class AddCachedParentIdsMigrator
    def self.call
      new.run
    end

    delegate :query_service, to: :change_set_persister

    def run
      query_service.custom_queries.memory_efficient_all.each do |resource|
        change_set = DynamicChangeSet.new(resource)
        change_set_persister.save(change_set: change_set)
      end
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
