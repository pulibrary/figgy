# frozen_string_literal: true

module GeoDiscovery
  class DocumentBuilder
    class DateBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      # Builds date fields such as layer year and modified date.
      # @param [AbstractDocument] discovery document
      def build(document)
        document.layer_year = layer_year
        document.layer_modified = layer_modified
        document.issued = issued
        document.temporal = temporal
      end

      private

        # Returns the date the layer was issued.
        # @return [String] date in XMLSchema format.
        def issued
          issued_val = resource_decorator.issued.first
          return unless issued_val
          datetime = "#{issued_val}-01-01"
          datetime = DateTime.parse(datetime).utc
          datetime.utc.xmlschema
        rescue ArgumentError
          nil
        end

        # Returns the date the work was modified.
        # @return [String] date in XMLSchema format.
        def layer_modified
          resource_decorator.model.updated_at.utc.xmlschema
        end

        # Returns a year associated with the layer.
        # @return [Integer] year
        def layer_year
          layer_year_date || layer_year_temporal || layer_year_created
        end

        # Returns a year from resource created date.
        # @return [Integer] year
        def layer_year_created
          year_from_date(resource_decorator.model.created_at)
        end

        # Returns a year from first value in date.
        # @return [Integer] year
        def layer_year_date
          date = resource_decorator.date
          return if date.empty?
          year_from_date(date.first)
        end

        # Returns a year from first value in temporal.
        # @return [Integer] year
        def layer_year_temporal
          return if resource_decorator.temporal.empty?
          year_from_date(resource_decorator.temporal.first)
        end

        # Adds issued year to an array of temporal values.
        # For better indexing.
        # @return [String] temporal values
        def temporal
          issued = resource_decorator.issued&.first&.to_s
          return resource_decorator.temporal unless issued
          resource_decorator.temporal << issued
        end

        # Extracts year as your digit integer from date string
        # @return [Integer] year
        def year_from_date(date)
          year = date.to_s.match(/(?<=\D|^)(\d{4})(?=\D|$)/)
          year ? year[0].to_i : nil
        end
    end
  end
end
