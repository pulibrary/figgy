# frozen_string_literal: true
module GeoResources
  module Discovery
    class DocumentBuilder
      class Wxs
        attr_reader :resource_decorator
        def initialize(resource_decorator)
          @resource_decorator = resource_decorator
          @config = Figgy.config['geoserver'].try(:with_indifferent_access)
        end

        # Returns the identifier to use with WMS/WFS/WCS services.
        # @return [String] wxs indentifier
        def identifier
          return unless file_set
          return file_set.id.to_s unless @config && visibility
          "#{@config[visibility][:workspace]}:#{file_set.id}" if @config[visibility][:workspace]
        end

        # Returns the wms server url.
        # @return [String] wms server url
        def wms_path
          return unless @config && visibility && file_set && file_set_format?
          "#{path}/#{@config[visibility][:workspace]}/wms"
        end

        # Returns the wfs server url.
        # @return [String] wfs server url
        def wfs_path
          return unless @config && visibility && file_set && file_set_format?
          "#{path}/#{@config[visibility][:workspace]}/wfs"
        end

        private

          # Gets the representative file set.
          # @return [FileSet] representative file set
          def file_set
            @file_set ||= begin
              member_id = resource_decorator.thumbnail_id.try(:first)
              return nil unless member_id
              members = resource_decorator.geo_members.select { |m| m.id == member_id }
              members.first.decorate unless members.empty?
            end
          end

          # Tests if the file set is a vector or raster format.
          # @return [Bool]
          def file_set_format?
            raster_file_set? || vector_file_set?
          end

          # Mime type of the file set.
          # @return [String]
          def file_set_mime_type
            file_set.mime_type.first
          end

          # Geoserver base url.
          # @return [String] geoserver base url
          def path
            @config[:url].chomp('/rest')
          end

          # Tests if the file set is a valid raster format.
          # @return [Bool]
          def raster_file_set?
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
end
