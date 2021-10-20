# frozen_string_literal: true
class ManifestBuilder
  class NavPlaceBuilder
    attr_reader :resource
    # @param [ManifestBuilder::RootNode] Root node for the resource being viewed
    def initialize(root_node)
      @root_node = resource
      @resource = root_node.resource
    end

    def apply(manifest)
      return manifest unless resource.is_a?(ScannedMap)
      return manifest unless geo_coverage
      manifest["navPlace"] = nav_place
      manifest["@context"] << nav_place_context
      manifest
    end

    private

      def nav_place
        {
          id: feature_collection_id,
          type: "FeatureCollection",
          features: [
            {
              id: feature_id,
              type: "Feature",
              properties: {},
              geometry: {
                type: "Polygon",
                coordinates: geo_coverage.to_coordinates
              }
            }
          ]
        }
      end

      def nav_place_context
        "http://iiif.io/api/extension/navplace/context.json"
      end

      def coverage
        resource.coverage || resource.primary_imported_metadata.coverage
      end

      def feature_collection_id
        "#{helper.manifest_url(resource)}/feature-collection/1"
      end

      def feature_id
        "#{helper.manifest_url(resource)}/feature/1"
      end

      def geo_coverage
        @geo_coverage ||= GeoCoverage.parse(coverage.try(:first))
      end

      def helper
        @helper ||= ManifestHelper.new
      end
  end
end
