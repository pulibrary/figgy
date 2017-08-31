# frozen_string_literal: true
class ManifestEventGenerator
  attr_reader :rabbit_exchange
  def initialize(rabbit_exchange)
    @rabbit_exchange = rabbit_exchange
  end

  def record_created(record)
    publish_message(
      message_with_collections("CREATED", record)
    )
  end

  def record_deleted(record)
    publish_message(
      message("DELETED", record)
    )
  end

  def record_updated(record)
    publish_message(
      message_with_collections("UPDATED", record)
    )
  end

  private

    def message(type, record)
      {
        "id" => record ? record.id.to_s : nil,
        "event" => type,
        "manifest_url" => helper.polymorphic_url([:manifest, record])
      }
    end

    def message_with_collections(type, record)
      output = message(type, record)
      if record.decorate.respond_to? :collections
        output["collection_slugs"] = record.decorate.collections.map { |collection| collection.try(:slug) }.compact
      end
      output
    end

    def publish_message(message)
      rabbit_exchange.publish(message.to_json)
    end

    def helper
      @helper ||= ManifestBuilder::ManifestHelper.new
    end
end
