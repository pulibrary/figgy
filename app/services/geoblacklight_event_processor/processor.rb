# frozen_string_literal: true

class GeoblacklightEventProcessor
  class Processor
    attr_reader :event
    def initialize(event)
      @event = event
    end

    private

      def event_type
        event['event']
      end

      def id
        event['id']
      end

      def doc
        event['doc']
      end

      def bulk?
        event['bulk'] == 'true'
      end

      def index
        @index ||= RSolr.connect(url: Figgy.config["pulmap_solr"][:url])
      end
  end
end
