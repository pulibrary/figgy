# frozen_string_literal: true
require 'active_support/core_ext/hash/indifferent_access'

module GeoResources
  module Discovery
    class DocumentBuilder
      class Wxs
        attr_reader :resource_decorator
        def initialize(resource_decorator)
          @resource_decorator = resource_decorator
          @config = GeoServer.config[visibility].try(:with_indifferent_access)
        end

        # Returns the identifier to use with WMS/WFS/WCS services.
        # @return [String] wxs indentifier
        def identifier
          return unless file_set
          return file_set.id.to_s unless @config && visibility
          "#{@config[:workspace]}:#{file_set.id}" if @config[:workspace]
        end

        # Returns the wms server url.
        # @return [String] wms server url
        def wms_path
          return unless @config && visibility && file_set
          "#{path}/#{@config[:workspace]}/wms"
        end

        # Returns the wfs server url.
        # @return [String] wfs server url
        def wfs_path
          return unless @config && visibility && file_set
          "#{path}/#{@config[:workspace]}/wfs"
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

          # Geoserver base url.
          # @return [String] geoserver base url
          def path
            @config[:url].chomp('/rest')
          end
      end
    end
  end
end
