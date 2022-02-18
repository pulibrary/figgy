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
    def processed?
      !processed_events(event_id: id).empty?
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
      return if processed? || unprocessable?
      job_klass.perform_later(ids_needing_updated)
      processed_event = ProcessedEvent.new
      change_set = ProcessedEventChangeSet.new(processed_event)
      change_set.validate(event_id: id)
      change_set_persister.save(change_set: change_set)
    end

    private

      # The ActiveJob Class used to update remote metadata
      # @return [Class]
      def job_klass
        VoyagerUpdateJob
      end

      # Retrieves the persisted ProcessedEvent Resources
      # @param event_id [String] the ID for the Voyager update event
      # @return [Array<ProcessedEvent>]
      def processed_events(event_id:)
        query_service.custom_queries.find_by_property(property: "event_id", value: event_id).to_a
      end

      # Retrieves the query service from the metadata adapter
      # @return [Valkyrie::Persistence::Postgres::QueryService]
      def query_service
        Valkyrie.config.metadata_adapter.query_service
      end

      # Retrieve the change set persister for repository resources
      # @return [ChangeSetPersister]
      def change_set_persister
        ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
      end
  end
end
