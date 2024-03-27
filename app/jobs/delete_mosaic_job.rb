# frozen_string_literal: true
class DeleteMosaicJob < ApplicationJob
  queue_as :low
  delegate :query_service, to: :metadata_adapter

  attr_reader :resource_id
  def perform(resource_id:)
    @resource_id = resource_id
    storage_adapter.delete(id: mosaic_id)
  rescue TileMetadataService::Error
    false
  end

  private

    def resource
      query_service.find_by(id: Valkyrie::ID.new(resource_id))
    end

    def mosaic_id
      TileMetadataService.new(resource: resource).storage_adapter_id
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def storage_adapter
      Valkyrie::StorageAdapter.find(:cloud_geo_derivatives)
    end
end
