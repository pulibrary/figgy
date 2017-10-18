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

    def manifest_url(record)
      helper.manifest_url(record)
    rescue
      ''
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
