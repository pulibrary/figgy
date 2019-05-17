# frozen_string_literal: true
class RegenerateDerivativesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    messenger.derivatives_deleted(file_set)
    Valkyrie::Derivatives::DerivativeService.for(id: file_set.id).cleanup_derivatives
    Valkyrie::Derivatives::DerivativeService.for(id: file_set.id).create_derivatives
    messenger.derivatives_created(file_set)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Rails.logger.error "Unable to find FileSet #{file_set_id}"
  rescue MiniMagick::Error => mini_magick_error
    Rails.logger.error "Failed to regenerate the derivatives for #{file_set.id}: #{mini_magick_error.message}"
    self.class.perform_later(file_set_id.to_s)
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def messenger
    @messenger ||= EventGenerator.new
  end
end
