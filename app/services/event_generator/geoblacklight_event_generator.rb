# frozen_string_literal: true
class EventGenerator
  class GeoblacklightEventGenerator
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
      if state == "takedown"
        record_deleted(record)
      elsif state == "complete"
        publish_message(
          message("UPDATED", record)
        )
      end
    end

    def record_member_updated(record)
      record_updated(record)
    end

    def valid?(record)
      return false if record.is_a?(FileSet)
      return false unless record.try(:geo_resource?)
      return false if errors?(record)

      true
    end

    private

      def publish_message(message)
        PulmapPublishingJob.perform_later(message)
      end

      def message(type, record)
        base_message(type, record).merge("doc" => document_generator(record).to_json)
      end

      def delete_message(type, record)
        base_message(type, record).merge("id" => slug(record))
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

      def document_generator(record)
        @document_generator ||= GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new)
      end

      def slug(record)
        GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug
      end

      def errors?(record)
        doc = document_generator(record).to_hash
        return true unless doc[:error].nil?

        false
      end
  end
end
