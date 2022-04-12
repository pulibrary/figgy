# frozen_string_literal: true
module GeoDiscovery
  class DocumentBuilder
    class Wxs
      attr_reader :resource_decorator
      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
        @config = Figgy.config["geoserver"].try(:with_indifferent_access)
      end

      # Returns the identifier to use with WMS/WFS/WCS services.
      # @return [String] wxs indentifier
      def identifier
        return resource_decorator.layer_name if resource_decorator.layer_name.present?
        return unless file_set
        return file_set.id.to_s unless @config && visibility
        "#{@config[visibility][:workspace]}:p-#{file_set.id}" if @config[visibility][:workspace]
      end

      # Returns the wms server url.
      # @return [String] wms server url
      def wms_path
        return resource_decorator.wms_url if resource_decorator.wms_url.present?
        return unless generate_wms_path?
        "#{path}/#{@config[visibility][:workspace]}/wms"
      end

      # Returns the wfs server url.
      # @return [String] wfs server url
      def wfs_path
        return resource_decorator.wfs_url if resource_decorator.wfs_url.present?
        return unless @config && visibility && file_set && vector_file_set?
        "#{path}/#{@config[visibility][:workspace]}/wfs"
      end

      # Returns the wfc server url.
      # @return [String] wcs server url
      def wcs_path
        return unless @config && visibility && file_set && raster_file_set?
        "#{path}/#{@config[visibility][:workspace]}/wcs"
      end

      # Returns the wmts server url.
      # @return [String] wmts server url
      def wmts_path
        return unless visibility == "open"
        TilePath.new(resource_decorator).wmts
      end

      # Returns the xzy tile server url.
      # @return [String] xyz server url
      def xyz_path
        return unless visibility == "open"
        TilePath.new(resource_decorator).xyz
      end

      private

        # Gets the representative file set.
        # @return [FileSet] representative file set
        def file_set
          @file_set ||= resource_decorator.geo_members&.first
        end

        # Mime type of the file set.
        # @return [String]
        def file_set_mime_type
          file_set.mime_type.first
        end

        # Determines if the wms path should be generated
        # @return [Boolean]
        def generate_wms_path?
          @config && visibility && file_set && (raster_file_set? || vector_file_set?)
        end

        # Geoserver base url.
        # @return [String] geoserver base url
        def path
          @config[:url].chomp("/rest")
        end

        # Tests if the file set is a valid raster format.
        # @return [Bool]
        def raster_file_set?
          return unless file_set
          ControlledVocabulary.for(:geo_raster_format).include? file_set_mime_type
        end

        # Tests if the file set is a valid vector format.
        # @return [Bool]
        def vector_file_set?
          ControlledVocabulary.for(:geo_vector_format).include? file_set_mime_type
        end

        # Returns the file set visibility if it's open and authenticated.
        # @return [String] file set visibility
        def visibility
          @visibility ||= begin
            visibility = resource_decorator.model.visibility.first
            visibility if valid_visibilities.include? visibility
          end
        end

        def valid_visibilities
          [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
           Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED]
        end
    end
  end
end
