# frozen_string_literal: true
module VoyagerUpdater
  class Event
    PROCESSABLE_EVENT_TYPE = "CHANGED_RECORDS"

    attr_reader :id, :dump_url, :dump_type
    delegate :ids_needing_updated, to: :dump

    # Constructor
    # @param init_hsh [Hash] the values for the serialized event resource
    def initialize(init_hsh)
      @id = init_hsh["id"].to_i
      @dump_url = init_hsh["dump_url"]
      @dump_type = init_hsh["dump_type"]
    end

    # Determine whether or not the Event has been processed
    # @return [Boolean]
    def enqueued?
      !ActiveJob::Base.queue_adapter.enqueued_jobs.find do |enqueued|
        enqueued[:job] == job_klass && enqueued[:args].first.include?(id.to_s)
      end.nil?
    end

    # Construct the data Dump object (using values retrieved from the endpoint)
    # @return [Dump]
    def dump
      @dump ||= Dump.new(dump_url)
    end

    # Using the type of data dump, determine whether or not the data can be processed
    # @return [Boolean]
    def unprocessable?
      dump_type != PROCESSABLE_EVENT_TYPE
    end

    # Process the event
    # @return [ProcessedEvent]
    def process!
      return if enqueued? || unprocessable?
      job_klass.perform_later(ids_needing_updated)
    end

    private

      # The ActiveJob Class used to update remote metadata
      # @return [Class]
      def job_klass
        VoyagerUpdateJob
      end
  end
end
