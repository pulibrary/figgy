# frozen_string_literal: true
class MosaicJob < ApplicationJob
  class JobRunning < StandardError; end
  discard_on TileMetadataService::Error
  retry_on JobRunning
  queue_as :low
  delegate :query_service, to: :metadata_adapter

  attr_reader :resource_id, :fingerprint
  def perform(resource_id:, fingerprint:)
    @resource_id = resource_id
    @fingerprint = fingerprint
    return unless valid_fingerprint?
    raise JobRunning if currently_running?
    path = TileMetadataService.new(resource: resource, generate: true).path
    # TODO: Trigger job/process to invalidate cache
  end

  private

    def valid_fingerprint?
      current_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: resource.id)
      current_fingerprint == fingerprint
    end

    def currently_running?
      workers = Sidekiq::Workers.new
      _, _, work = workers.find { |_, _, work| work.dig("payload", "args", 0, "job_class") == "MosaicJob" && work.dig("payload", "args", 0, "arguments", 0, "resource_id") == resource.id }
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
