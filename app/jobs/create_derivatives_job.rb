# frozen_string_literal: true
class CreateDerivativesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # @param file_set_id [string] stringified Valkyrie id
  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    Valkyrie::Derivatives::DerivativeService.for(FileSetChangeSet.new(file_set)).create_derivatives
    messenger.derivatives_created(file_set)
    CheckFixityJob.set(queue: queue_name).perform_later(file_set_id)
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def messenger
    @messenger ||= EventGenerator.new
  end
end
