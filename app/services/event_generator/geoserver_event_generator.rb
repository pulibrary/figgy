# frozen_string_literal: true
class EventGenerator
  class GeoserverEventGenerator
    def initialize(_); end;

    def derivatives_created(record)
      params = message_generator.new(resource: record).generate
      GeoserverPublishJob.perform_later("CREATE", params)
    end

    def derivatives_deleted(record)
      params = message_generator.new(resource: record).generate
      GeoserverPublishJob.perform_later("DELETE", params)
    end

    def record_created(record); end

    def record_deleted(record); end

    def record_updated(record)
      # Iterate through all geo members of parent resource.
      geo_members = record.decorate.try(:geo_members) || []
      geo_members.each do |member|
        next unless member.derivative_file
        params = message_generator.new(resource: member).generate
        GeoserverPublishJob.perform_later("UPDATE", params)
      end
    end

    def record_member_updated(record); end

    def valid?(record)
      return true if record.is_a?(VectorResource) || record.is_a?(RasterResource)
      return true if geo_file_set?(record)
      false
    end

    private

      def geo_file_set?(record)
        return false unless record.is_a?(FileSet)
        return false unless vector_file_set?(record) || raster_file_set?(record)
        return true if record.derivative_file
      end

      def message_generator
        GeoserverMessageGenerator
      end

      def raster_file_set?(record)
        ControlledVocabulary.for(:geo_raster_format).include?(record.mime_type.try(:first))
      end

      def vector_file_set?(record)
        ControlledVocabulary.for(:geo_vector_format).include?(record.mime_type.try(:first))
      end
  end
end
