# frozen_string_literal: true

module GeoDiscovery
  class DocumentBuilder
    class LayerInfoBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      # Builds fields about the geospatial file such as geometry and format.
      # @param [AbstractDocument] discovery document
      def build(document)
        document.geom_type = geom_type
        document.format = format
      end

      private

        # Gets geo file set decorator
        # @return [FileSet] geo file set decorator
        def file_set
          @file_set ||= begin
            members = resource_decorator.geo_members
            members.first.decorate unless members.empty?
          end
        end

        # Uses file mime type to determine file format.
        # @return [String] file format code
        def format
          if ControlledVocabulary.for(:geo_image_format).include? geo_mime_type
            ControlledVocabulary.for(:geo_image_format).find(geo_mime_type).label
          elsif ControlledVocabulary.for(:geo_raster_format).include? geo_mime_type
            ControlledVocabulary.for(:geo_raster_format).find(geo_mime_type).label
          elsif ControlledVocabulary.for(:geo_vector_format).include? geo_mime_type
            ControlledVocabulary.for(:geo_vector_format).find(geo_mime_type).label
          end
        end

        # Returns the 'geo' mime type of the first file attached to the work.
        # @return [String] file mime type
        def geo_mime_type
          return unless file_set
          file_set.mime_type.first
        end

        # Uses parent work class to determine file geometry type.
        # These geom types are used in geoblacklight documents.
        # @return [String] file geometry type
        def geom_type
          return "Image" if resource_decorator.model.is_a?(ScannedMap)
          return "Raster" if resource_decorator.model.is_a?(RasterResource)
          return vector_geom_type if resource_decorator.model.is_a?(VectorResource)
        end

        # Returns the geometry for a vector file.
        # @return [String] vector geometry
        def vector_geom_type
          return "Mixed" unless file_set
          geometry = file_set.try(:geometry).try(:first) || "Mixed"
          vector_geom_clean(geometry)
        end

        # Returns unwanted strings from OGR/GDAL geometry types.
        # @return [String] cleaned geometry
        def vector_geom_clean(value)
          return "Mixed" if value == "None"
          removable_strings = ["Multi ", "3D ", " String", "Measured "]
          removable_strings.each do |s|
            value = value.gsub(s, "")
          end

          value
        end
    end
  end
end
