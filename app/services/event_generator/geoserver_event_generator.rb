# frozen_string_literal: true
class EventGenerator
  class GeoserverEventGenerator
    attr_reader :rabbit_exchange

    def initialize(rabbit_exchange)
      @rabbit_exchange = rabbit_exchange
    end

    def derivatives_created(record)
      publish_message(
        message("CREATED", record)
      )
    end

    def derivatives_deleted(record)
      publish_message(
        message("DELETED", record)
      )
    end

    def record_created(record); end

    def record_deleted(record); end

    def record_updated(record); end

    def record_member_updated(record); end

    def valid?(record)
      return false unless record.is_a?(FileSet)
      return false unless geo_file_set?(record)
      return true if record.derivative_file
      false
    end

    private

      def base_message(record)
        message_generator.new(resource: record).generate
      end

      def geo_file_set?(record)
        vector_file_set?(record) || raster_file_set?(record)
      end

      def message(type, record)
        base_message(record).merge("event" => type)
      end

      def message_generator
        GeoserverMessageGenerator
      end

      def publish_message(message)
        rabbit_exchange.publish(message.to_json)
      end

      def raster_file_set?(record)
        ControlledVocabulary.for(:geo_raster_format).include?(record.mime_type.first)
      end

      def vector_file_set?(record)
        ControlledVocabulary.for(:geo_vector_format).include?(record.mime_type.first)
      end
  end
end
