module Migrations
  # Converts the old boolean `featurable` flag into the list of collection and
  # ephemera project ids a resource is highlighted in.
  #
  # Highlighting used to be all-or-nothing, so a resource that was highlighted
  # becomes highlighted in every collection it belongs to plus its ancestor
  # ephemera project. Curators can then narrow that down per collection.
  # Resources that were explicitly not highlighted have the flag cleared.
  class FeaturableMigrator
    TRUE_VALUES = ["1", "true"].freeze

    def self.call
      new.run
    end

    # @return [Integer] the number of resources that were migrated
    def run
      migrated = 0
      resources.each do |resource|
        legacy_value = legacy_value_for(resource)
        next if legacy_value.nil?

        migrate(resource, TRUE_VALUES.include?(legacy_value))
        migrated += 1
        logger.info "Migrated featurable for #{resource.class} #{resource.id}"
      end
      migrated
    end

    private

      # Resources that already hold ids have nothing to migrate, so anything
      # other than a single legacy boolean value is left alone.
      # @return [String, nil] the boolean value the resource still holds
      def legacy_value_for(resource)
        values = Array.wrap(resource.featurable).map(&:to_s)
        return nil unless values.length == 1
        return nil unless FeaturableProperty::LEGACY_VALUES.include?(values.first)
        values.first
      end

      def migrate(resource, highlighted)
        change_set = ChangeSet.for(resource)
        change_set.validate(featurable: highlighted ? featurable_ids(resource) : [])
        change_set_persister.save(change_set: change_set)
      end

      # Every place the resource could be highlighted: its collections and, for
      # ephemera folders, the project it lives in.
      # @return [Array<Valkyrie::ID>]
      def featurable_ids(resource)
        project_ids = Array.wrap(Wayfinder.for(resource).try(:ephemera_projects)).compact.map(&:id)
        (Array.wrap(resource.member_of_collection_ids) + project_ids).uniq
      end

      def resources
        query_service.custom_queries.find_by_property_not_empty(property: :featurable, lazy: true)
      end

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
