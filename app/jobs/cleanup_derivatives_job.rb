# frozen_string_literal: true
#
# An asynchronous job for cleaning derivative Valkyrie::StorageAdapter::File objects
class CleanupDerivativesJob < ApplicationJob
  # Uses the query service from the metadata adapter
  # @return [Valkyrie::Persistence::Memory::QueryService,
  #   Valkyrie::Persistence::Solr::QueryService, Valkyrie::Persistence::Postgres::QueryService,
  #   Valkyrie::Persistence::ActiveFedora::QueryService]
  delegate :query_service, to: :metadata_adapter

  # Perform the cleanup as a job
  # @param file_set_id [Valkyrie::ID, String] the ID for the Valkyrie Resource
  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    Valkyrie::DerivativeService.for(FileSetChangeSet.new(file_set)).cleanup_derivatives
  end

  private

    # Retrieve the current metadata adapter configured for Figgy
    # @return [Valkyrie::Persistence::Memory::MetadataAdapter, Valkyrie::Persistence::Solr::MetadataAdapter,
    #   Valkyrie::Persistence::Postgres::MetadataAdapter, Valkyrie::Persistence::ActiveFedora::MetadataAdapter]
    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
end
