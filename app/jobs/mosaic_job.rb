# frozen_string_literal: true
class MosaicJob < ApplicationJob
  discard_on TileMetadataService::Error
  queue_as :low
  delegate :query_service, to: :metadata_adapter

  def perform(resource_id)
    resource = query_service.find_by(id: Valkyrie::ID.new(resource_id))
    TileMetadataService.new(resource: resource).path
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
