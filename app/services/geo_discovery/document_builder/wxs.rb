# frozen_string_literal: true
module GeoDiscovery
  class DocumentBuilder
    class Wxs
      attr_reader :resource_decorator
      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
        @geoserver_config = Figgy.config["geoserver"].try(:with_indifferent_access)
        @geodata_config = Figgy.config["geodata"].try(:with_indifferent_access)
      end

      # Returns the identifier to use with WMS/WFS/WCS services.
      # @return [String] wxs indentifier
      def identifier
        return resource_decorator.layer_name if resource_decorator.layer_name&.first&.present?
        return unless file_set
        return file_set.id.to_s unless @geoserver_config && visibility
        "#{@geoserver_config[visibility][:workspace]}:p-#{file_set.id}" if @geoserver_config[visibility][:workspace]
      end

      # Returns the wms server url.
      # @return [String] wms server url
      def wms_path
        url = Array.wrap(resource_decorator.wms_url)
        return url.first if url.try(:first).present?
        return unless generate_wms_path?
        "#{path}/#{@geoserver_config[visibility][:workspace]}/wms"
      end

      # Returns the wfs server url.
      # @return [String] wfs server url
      def wfs_path
        url = Array.wrap(resource_decorator.wfs_url)
        return url.first if url.try(:first).present?
        return unless @geoserver_config && visibility && file_set && vector_file_set?
        "#{path}/#{@geoserver_config[visibility][:workspace]}/wfs"
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

      def pmtiles_path
        return unless generate_pmtiles_path?
        "#{@geodata_config[visibility][:url]}/#{cloud_file_path}"
      end

      private

        def cloud_file_path
          @cloud_file_path ||= begin
            file = file_set.cloud_derivative_files&.first
            file.file_identifiers.first.to_s.gsub("cloud-geo-derivatives-shrine://", "") if file
          end
        end

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

        def generate_pmtiles_path?
          @geodata_config && visibility && file_set && vector_file_set? && cloud_file_path
        end

        # Determines if the wms path should be generated
        # @return [Boolean]
        def generate_wms_path?
          @geoserver_config && visibility && file_set && vector_file_set?
        end

        # Geoserver base url.
        # @return [String] geoserver base url
        def path
          @geoserver_config[:url].chomp("/rest")
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
