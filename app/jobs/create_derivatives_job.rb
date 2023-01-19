# frozen_string_literal: true
class CreateDerivativesJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # @param file_set_id [string] stringified Valkyrie id
  def perform(file_set_id)
    Valkyrie::Derivatives::DerivativeService.for(id: file_set_id).create_derivatives
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    file_set.processing_status = "processed"
    metadata_adapter.persister.save(resource: file_set)
    messenger.derivatives_created(file_set)
    publish_to_geoserver(file_set)
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

  def publish_to_geoserver(file_set)
    return unless ControlledVocabulary.for(:geo_vector_format).include?(file_set.mime_type.try(:first))
    return if file_set.derivative_files.blank?
    GeoserverPublishJob.perform_later(operation: "derivatives_create", resource_id: file_set.id.to_s)
  end
end
