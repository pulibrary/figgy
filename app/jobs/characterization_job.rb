# frozen_string_literal: true
class CharacterizationJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # @param file_set_id [string] stringified Valkyrie id
  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    Valkyrie::Derivatives::FileCharacterizationService.for(file_set: file_set, persister: metadata_adapter.persister).characterize

    CreateDerivativesJob.set(queue: queue_name).perform_later(file_set_id)
  rescue Valkyrie::Persistence::ObjectNotFoundError => error
    Valkyrie.logger.warn "#{self.class}: #{error}: Failed to find the resource #{file_set_id}"
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
