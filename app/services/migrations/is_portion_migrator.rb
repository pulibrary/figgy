module Migrations
  class IsPortionMigrator
    def self.call
      new.run
    end

    def run
      resources = query_service.custom_queries.find_by_property_not_empty(property: :portion_note)
      total = resources.count
      counter = 0
      resources.each do |resource|
        counter += 1
        cs = ChangeSet.for(resource)
        cs.validate(is_portion: true)
        change_set_persister.save(change_set: cs)
        logger.info "Processed #{counter} / #{total} : #{resource.class} #{resource.id}"
      end
    end

    private

      def query_service
        @query_service ||= Valkyrie.config.metadata_adapter.query_service
      end

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        )
      end

      def logger
        @logger ||= Logger.new($stdout)
      end
  end
end
