# frozen_string_literal: true

class VoyagerUpdateJob < ApplicationJob
  # Update all resources with Voyager metadata
  # @param ids [Array<String>]
  def perform(ids)
    logger.info "Processing updates for IDs: #{ids.join(', ')}" unless ids.empty?

    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ids.each do |id|
        begin
          results = query_service.custom_queries.find_by_string_property(property: "source_metadata_identifier", value: id).to_a
          next if results.empty?

          resource = results.first
          change_set = DynamicChangeSet.new(resource)
          next unless change_set.respond_to?(:apply_remote_metadata?) && change_set.respond_to?(:source_metadata_identifier)

          change_set.prepopulate!
          change_set.validate(refresh_remote_metadata: true)

          logger.info "Processing updates for Voyager record #{id} imported into resource #{resource.id}..."
          buffered_change_set_persister.save(change_set: change_set)
        rescue StandardError => error
          warn "#{self.class}: Unable to process the changed Voyager record #{id}: #{error}"
        end
      end
    end
  end

  private

    # Retrieves the query service from the metadata adapter
    # @return [Valkyrie::Persistence::Postgres::QueryService]
    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    # Construct the persister for saving Resources
    # @return [ChangeSetPersister]
    def change_set_persister
      ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
