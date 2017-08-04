# frozen_string_literal: true
class CharacterizationJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    file_node = file_set.original_file
    metadata_adapter.persister.buffer_into_index do |buffered_adapter|
      Valkyrie::FileCharacterizationService.for(file_node: file_node, persister: buffered_adapter.persister).characterize
    end
    CreateDerivativesJob.perform_later(file_set_id)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
