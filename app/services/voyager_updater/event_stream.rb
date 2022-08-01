# frozen_string_literal: true
module VoyagerUpdater
  class EventStream
    attr_reader :url

    # Constructor
    # @param url [String]
    def initialize(url)
      @url = url
    end

    # Retrieve and deserialize all events from the service endpoint
    # @return [Array<Event>]
    def events
      @events ||= parsed_json.map do |json_record|
        VoyagerUpdater::Event.new(json_record)
      end
    end

    # Process each event which has been populated
    def process!
      events.each(&:process!)
    end

    private

      # Retrieve the event values and parse the response from JSON
      # @return [Hash]
      def parsed_json
        @parsed_json ||= JSON.parse(URI.open(url).read)
      end
  end
end
