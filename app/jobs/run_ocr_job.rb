# frozen_string_literal: true
class RunOCRJob < ApplicationJob
  queue_as :super_low
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    derivative_service_factory.new(id: file_set_id).create_derivatives
  rescue Valkyrie::Persistence::ObjectNotFoundError, Valkyrie::StorageAdapter::FileNotFound => error
    Valkyrie.logger.warn "#{self.class}: #{error}: Failed to find the resource #{file_set_id}"
  end

  private

    def derivative_service_factory
      @derivative_service_factory ||= HocrDerivativeService::Factory.new(change_set_persister: change_set_persister)
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
