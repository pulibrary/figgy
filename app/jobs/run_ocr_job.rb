# frozen_string_literal: true
class RunOCRJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    change_set = DynamicChangeSet.new(file_set)
    derivative_service.new(change_set).create_derivatives
  end

  private

    def derivative_service
      @derivative_service ||= HocrDerivativeService::Factory.new(change_set_persister: change_set_persister)
    end

    def change_set_persister
      @change_set_persister ||= PlumChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
