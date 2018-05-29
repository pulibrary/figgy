# frozen_string_literal: true
class EphemeraFolderMigrator
  class << self
    # Invokes the migration
    def call
      resources.each do |resource|
        # Ensures that all member EphemeraFolders have their state properly updated
        cs = DynamicChangeSet.new(resource)
        cs.prepopulate!
        change_set_persister.save(change_set: cs)
      end
    end

    private

      def storage_adapter
        Valkyrie.config.storage_adapter
      end

      # Retrieves the metadata adapter used to update the EphemeraFolders
      # @return [Valkyrie::MetadataAdapter]
      def adapter
        Valkyrie.config.metadata_adapter
      end

      def change_set_persister
        ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
      end

      # Retrieves the query service from the metadata adapter
      # @return [Valkyrie::QueryService]
      def query_service
        adapter.query_service
      end

      # Retrieves the model for the resource being updated during the migration
      # @return [Class]
      def model
        EphemeraBox
      end

      # Retrieves all of the resources being updated during the migration
      # @return [Enumerable<Valkyrie::Resource>]
      def resources
        query_service.find_all_of_model(model: model)
      end
  end
end
