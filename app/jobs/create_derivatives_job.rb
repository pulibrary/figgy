# frozen_string_literal: true
class CreateDerivativesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # @param file_set_id [string] stringified Valkyrie id
  def perform(file_set_id)
    derivative_service = find_derivative_service(file_set_id)
    derivative_service.create_derivatives
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    file_set.processing_status = "processed"
    metadata_adapter.persister.save(resource: file_set)
    messenger.derivatives_created(file_set)
    CheckFixityJob.perform_later(file_set_id)
  rescue Valkyrie::Persistence::ObjectNotFoundError => not_found_error
    Valkyrie.logger.warn "#{self.class}: #{not_found_error}: Failed to find the resource #{file_set_id}"
  rescue StandardError => error
    Valkyrie.logger.error "Failed to generate derivatives for #{file_set_id}: #{error.class}: #{error.message}"
    # A StaleObject error will be raised if this is not reloaded
    reloaded_derivative_service = find_derivative_service(file_set_id)
    reloaded_derivative_service.cleanup_derivatives
    raise error
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def messenger
    @messenger ||= EventGenerator.new
  end

  private

    # @param file_set_id [String] the ID for the FileSet
    # @return
    def find_derivative_service(file_set_id)
      Valkyrie::Derivatives::DerivativeService.for(id: file_set_id)
    end
end
