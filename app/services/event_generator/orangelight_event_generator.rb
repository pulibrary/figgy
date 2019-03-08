# frozen_string_literal: true
class EventGenerator
  class OrangelightEventGenerator
    attr_reader :rabbit_exchange

    def initialize(rabbit_exchange)
      @rabbit_exchange = rabbit_exchange
    end

    def derivatives_created(record); end

    def derivatives_deleted(record); end

    def record_created(record); end

    def record_deleted(record)
      publish_message(
        delete_message("DELETED", record)
      )
    end

    def record_updated(record)
      state = record.state.first
      return unless state == "complete"
      publish_message(
        message("UPDATED", record)
      )
    end

    def record_member_updated(record)
      record_updated(record)
    end

    def valid?(record)
      record.is_a? Coin
    end

    private

      def publish_message(message)
        rabbit_exchange.publish(message.to_json)
      end

      def message(type, record)
        base_message(type, record).merge("doc" => generate_document(record))
      end

      def delete_message(type, record)
        base_message(type, record).merge("id" => record.decorate.orangelight_id)
      end

      def base_message(type, record)
        {
          "id" => record.id.to_s,
          "event" => type,
          "bulk" => bulk_value
        }
      end

      def bulk_value
        if ENV["BULK"]
          "true"
        else
          "false"
        end
      end

      def generate_document(record)
        OrangelightDocument.new(record).to_json
      end
  end
end
