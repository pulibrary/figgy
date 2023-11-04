# frozen_string_literal: true
class MosaicJob < ApplicationJob
  class JobRunning < StandardError; end
  discard_on TileMetadataService::Error
  retry_on JobRunning
  queue_as :low
  delegate :query_service, to: :metadata_adapter

  attr_reader :resource_id
  def perform(resource_id)
    @resource_id = resource_id
    raise JobRunning if currently_running?
    TileMetadataService.new(resource: resource, generate: true).path
  end

  private

    def currently_running?
      workers = Sidekiq::Workers.new
      _, _, work = workers.find { |_, _, work| work.dig("payload", "args", 0, "job_class") == "MosaicJob" && work.dig("payload", "args", 0, "arguments", 0) == resource.id }
      return true if work
      false
    end

    def resource
      query_service.find_by(id: Valkyrie::ID.new(resource_id))
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
