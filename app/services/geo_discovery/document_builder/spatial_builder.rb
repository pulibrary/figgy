# frozen_string_literal: true

module GeoDiscovery
  class DocumentBuilder
    class SpatialBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      # Builds spatial fields such as bounding box and solr geometry.
      # @param [AbstractDocument] discovery document
      def build(document)
        document.solr_coverage = to_solr
      end

      private

        # Parses coverage field from geo resource and instantiates a coverage object.
        # @return [GeoCoverage] coverage object
        def coverage
          @coverage ||= begin
            valid_coverages = resource_decorator.coverage.map { |c| GeoCoverage.parse(c) }.compact
            valid_coverages.first
          end
        end

        # Returns the coverage in solr format. For example:
        # `ENVELOPE(minX, maxX, maxY, minY)`
        # @see 'https://cwiki.apache.org/confluence/display/solr/Spatial+Search'
        # @return [String] coverage in solr format
        def to_solr
          "ENVELOPE(#{coverage.w}, #{coverage.e}, #{coverage.n}, #{coverage.s})"
        rescue
          ""
        end
    end
  end
end
