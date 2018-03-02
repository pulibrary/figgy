# frozen_string_literal: true
class CreateDerivativesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    Valkyrie::Derivatives::DerivativeService.for(FileSetChangeSet.new(file_set)).create_derivatives
    CheckFixityJob.set(queue: queue_name).perform_later(file_set_id)
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
