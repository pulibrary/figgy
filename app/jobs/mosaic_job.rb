# frozen_string_literal: true
class MosaicJob < ApplicationJob
  discard_on TileMetadataService::Error
  queue_as :low
  delegate :query_service, to: :metadata_adapter

  attr_reader :resource_id
  def perform(resource_id)
    @resource_id = resource_id
    return if currently_enqueued?
    TileMetadataService.new(resource: resource).path
  end

  private

    def currently_enqueued?
      queue = Sidekiq::Queue.new("low")
      job = queue.find { |j| j.item.dig("args", 0, "job_class") == "MosaicJob" && j.item.dig("args", 0, "arguments", 0) == resource_id }
      return true if job
      false
    end

    def resource
      query_service.find_by(id: Valkyrie::ID.new(resource_id))
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
