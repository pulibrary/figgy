# frozen_string_literal: true
class UpdateCompletedEphemeraFolders < ActiveRecord::Migration[5.1]
  # Perform the one-way migration for updating EphemeraFolders
  def change
    # Ensures that all member EphemeraFolders have their state properly updated
    resources.each do |resource|
      cs = DynamicChangeSet.new(resource)
      cs.prepopulate!
      change_set_persister.save(change_set: cs)
    end
  end

  private

    # Construct a ChangeSetPersister for persisting the EphemeraBoxes and member EphemeraFolders
    # @return [ChangeSetPersister]
    def change_set_persister
      ChangeSetPersister.new(
        metadata_adapter: Valkyrie.config.metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    # Retrieves the query service from the metadata adapter
    # @return [Valkyrie::Persistence::Postgres::QueryService]
    def query_service
      Valkyrie.config.metadata_adapter.query_service
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
