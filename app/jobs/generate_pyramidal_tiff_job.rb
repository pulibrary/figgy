# frozen_string_literal: true

class GeneratePyramidalTiffJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    change_set_persister = Valkyrie::Derivatives::DerivativeService.for(id: file_set_id).change_set_persister
    vips_derivative_factory = VIPSDerivativeService::Factory.new(change_set_persister: change_set_persister.with(storage_adapter: Valkyrie::StorageAdapter.find(:pyramidal_derivatives)))
    vips_derivative_factory.new(id: file_set_id).cleanup_derivatives
    vips_derivative_factory.new(id: file_set_id).create_derivatives
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Rails.logger.error "Unable to find FileSet #{file_set_id}"
  end
end
