# frozen_string_literal: true
class MosaicJob < ApplicationJob
  discard_on MosaicService::Error
  delegate :query_service, to: :metadata_adapter

  def perform(resource_id)
    resource = query_service.find_by(id: Valkyrie::ID.new(resource_id))
    return unless resource.decorate.raster_set?
    MosaicService.new(resource: resource).path
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
