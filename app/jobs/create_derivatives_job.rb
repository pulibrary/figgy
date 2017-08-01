# frozen_string_literal: true
class CreateDerivativesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    Valkyrie::DerivativeService.for(FileSetChangeSet.new(file_set)).create_derivatives
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
