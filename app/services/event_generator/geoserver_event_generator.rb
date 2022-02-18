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
      # Attempt to delete from both public and restricted
      # workspaces to make sure all traces of the file
      # are cleaned up on GeoServer.
      publish_message(
        message("DELETED", record, public_workspace)
      )
      publish_message(
        message("DELETED", record, authenticated_workspace)
      )
    end

    def record_created(record)
    end

    def record_deleted(record)
    end

    def record_updated(record)
      # Iterate through all geo members of parent resource.
      geo_members = record.decorate.try(:geo_members) || []
      geo_members.each do |member|
        next unless member.derivative_file
        publish_message(
          message("UPDATED", member)
        )
      end
    end

    def record_member_updated(record)
    end

    def valid?(record)
      return true if record.is_a?(VectorResource) || record.is_a?(RasterResource)
      return true if geo_file_set?(record)
      false
    end

    private

      def authenticated_workspace
        Figgy.config["geoserver"]["authenticated"]["workspace"]
      end

      def base_message(record)
        message_generator.new(resource: record).generate
      end

      def geo_file_set?(record)
        return false unless record.is_a?(FileSet)
        return false unless vector_file_set?(record) || raster_file_set?(record)
        return true if record.derivative_file
      end

      def merged_values(type, workspace)
        {
          "event" => type,
          "workspace" => workspace
        }
      end

      def message(type, record, workspace = nil)
        values = merged_values(type, workspace).delete_if { |_k, v| v.nil? }
        base_message(record).merge(values)
      end

      def message_generator
        GeoserverMessageGenerator
      end

      def public_workspace
        Figgy.config["geoserver"]["open"]["workspace"]
      end

      def publish_message(message)
        rabbit_exchange.publish(message.to_json)
      end

      def raster_file_set?(record)
        ControlledVocabulary.for(:geo_raster_format).include?(record.mime_type.try(:first))
      end

      def vector_file_set?(record)
        ControlledVocabulary.for(:geo_vector_format).include?(record.mime_type.try(:first))
      end
  end
end
