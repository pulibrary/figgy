# frozen_string_literal: true
module GeoDiscovery
  class DocumentBuilder
    class Wxs
      attr_reader :resource_decorator
      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
        @geodata_config = Figgy.config["geodata"].try(:with_indifferent_access)
      end

      # @return [String] wxs indentifier
      def identifier
        return unless file_set
        file_set.id.to_s
      end

      # Returns the cloud optimized geotiff data url.
      # @return [String] cog data url
      def cog_path
        return unless generate_cog_path?
        "#{@geodata_config[visibility][:url]}/#{cloud_file_path}"
      end

      # Returns the pmtiles data url.
      # @return [String] pmtiles data url
      def pmtiles_path
        return unless generate_pmtiles_path?
        "#{@geodata_config[visibility][:url]}/#{cloud_file_path}"
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

        # Determines if the cog path should be generated
        # @return [Boolean]
        def generate_cog_path?
          @geodata_config && visibility && file_set && raster_file_set? && cloud_file_path
        end

        # Determines if the pmtiles path should be generated
        # @return [Boolean]
        def generate_pmtiles_path?
          @geodata_config && visibility && file_set && vector_file_set? && cloud_file_path
        end

        # Tests if the file set is a valid vector format.
        # @return [Bool]
        def vector_file_set?
          ControlledVocabulary.for(:geo_vector_format).include? file_set_mime_type
        end

        # Tests if the file set is a valid raster format.
        # @return [Bool]
        def raster_file_set?
          ControlledVocabulary.for(:geo_raster_format).include? file_set_mime_type
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
