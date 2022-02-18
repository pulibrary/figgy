# frozen_string_literal: true

class EventGenerator
  class ManifestEventGenerator
    attr_reader :rabbit_exchange

    def initialize(rabbit_exchange)
      @rabbit_exchange = rabbit_exchange
    end

    def derivatives_created(record)
    end

    def derivatives_deleted(record)
    end

    def record_created(record)
      return unless record
      publish_message(
        message_with_collections("CREATED", record)
      )
    end

    def record_deleted(record)
      return unless record
      publish_message(
        message("DELETED", record)
      )
    end

    def record_updated(record)
      return unless record
      publish_message(
        message_with_collections("UPDATED", record)
      )
    end

    def record_member_updated(record)
      return unless record
      publish_message(
        message_with_collections("MEMBER_UPDATED", record)
      )
    end

    def valid?(_record)
      true
    end

    private

      def manifest_url(record)
        helper.manifest_url(record)
      end

      def message(type, record)
        {
          "id" => record ? record.id.to_s : nil,
          "event" => type,
          "manifest_url" => manifest_url(record)
        }
      end

      def collection_slugs_for(resource)
        return [] unless resource.decorate.try(:collection_slugs)
        resource.decorate.collection_slugs.compact
      end

      def message_with_collections(type, record)
        output = message(type, record)
        output["collection_slugs"] = collection_slugs_for record
        output
      end

      def publish_message(message)
        rabbit_exchange.publish(message.to_json)
      end

      def helper
        @helper ||= ManifestBuilder::ManifestHelper.new
      end
  end
end
