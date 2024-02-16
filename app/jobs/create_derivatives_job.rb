# frozen_string_literal: true
class CreateDerivativesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # @param file_set_id [string] stringified Valkyrie id
  def perform(file_set_id)
    Valkyrie::Derivatives::DerivativeService.for(id: file_set_id).create_derivatives
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    file_set.processing_status = "processed"
    file_set = change_set_persister.save(change_set: ChangeSet.for(file_set))
    messenger.derivatives_created(file_set)
    LocalFixityJob.perform_later(file_set_id)
  rescue Valkyrie::Persistence::ObjectNotFoundError => error
    Valkyrie.logger.warn "#{self.class}: #{error}: Failed to find the resource #{file_set_id}"
  rescue Valkyrie::StorageAdapter::FileNotFound => error
    Valkyrie.logger.warn "#{self.class}: #{error}: Failed to find the resource #{file_set_id}"
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def messenger
    @messenger ||= EventGenerator.new
  end

  def change_set_persister
    ChangeSetPersister.default
  end
end
