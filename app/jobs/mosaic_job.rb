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
    TileMetadataService.new(resource: resource, generate: true).path
  end

  private

    # Compare the mosaic fingerprint passed in when the job was created with the
    # current fingerprint. If they don't match, this implies that the mosiac
    # structure was changed and the job should exit without generating a mosaic
    # document. Another mosaic job on the queue will have the current fingerprint value.
    def valid_fingerprint?
      current_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: resource.id)
      current_fingerprint == fingerprint
    end

    # Only one MosaicJob per resource should run at a time. This is to prevent conditions
    # where mosaic jobs finish out of order and produce an incorrect mosaic json document.
    def currently_running?
      work_set = Sidekiq::WorkSet.new
      _, _, work = work_set.find do |_, _, work|
        payload = JSON.parse(work.payload)
        payload.dig("args", 0, "job_class") == "MosaicJob" && payload.dig("args", 0, "arguments", 0, "resource_id") == resource.id
      end

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
