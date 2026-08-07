module Migrations
  # Converts boolean `featurable` values into lists of IDs if boolean value was
  # previously set to true ("1"). An item will be featured in all collections and
  # EphemeraProjects that it is a member of. Outputs a CSV of all migrated resources
  # so they can be adjusted (removed from Collections or Projects) later if needed.
  class FeaturableMigrator
    def self.call(csv_path: nil)
      path = csv_path || Rails.root.join("tmp", "featurable_migration.csv")
      new(csv_path: path).run
    end

    attr_reader :csv_path
    def initialize(csv_path:)
      @csv_path = csv_path
    end

    def run
      CSV.open(csv_path, "w") do |csv|
        resources.each do |resource|
          legacy_value = legacy_value_for(resource)
          next if legacy_value.nil?

          migrate(resource, legacy_value)
          csv << [resource.id]
          logger.info "Migrated featurable for #{resource.class} #{resource.id}"
        end
      end
    end

    private

      # Returns the featurable value if it is boolean ("0" or "1")
      def legacy_value_for(resource)
        return nil unless resource.featurable.length == 1
        value = resource.featurable.first
        return nil unless ["0", "1"].include?(value)
        value
      end

      def migrate(resource, legacy_value)
        featurable = legacy_value == "1" ? featurable_ids(resource) : []
        change_set = ChangeSet.for(resource)
        change_set.validate(featurable: featurable)
        change_set_persister.save(change_set: change_set)
      end

      # All Collections or EphemeraProjects a resource could be featured in
      def featurable_ids(resource)
        project_ids = Array.wrap(Wayfinder.for(resource).try(:ephemera_projects)).map(&:id)
        (Array.wrap(resource.member_of_collection_ids) + project_ids)
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
        @logger ||= Logger.new(STDOUT)
      end
  end
end
