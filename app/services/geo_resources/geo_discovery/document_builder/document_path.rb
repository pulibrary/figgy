# frozen_string_literal: true
module GeoResources
  module GeoDiscovery
    class DocumentBuilder
      class DocumentPath
        attr_reader :resource_decorator
        def initialize(resource_decorator)
          @resource_decorator = resource_decorator
        end

        # Returns url for downloading the original file.
        # @return [String] original file download url
        def file_download
          file_set = geo_file_set
          return unless file_set
          id = file_set.original_file.id.to_s
          path = url_helpers.download_path(resource_id: file_set.id.to_s, id: id)
          "#{protocol}://#{host}#{path}"
        end

        # Returns url for downloading the metadata file.
        # @param [String] metadata file format to download
        # @return [String] metadata download url
        def metadata_download(format)
          file_set = metadata_file_set(format)
          return unless file_set
          id = file_set.original_file.id.to_s
          path = url_helpers.download_path(resource_id: file_set.id.to_s, id: id)
          "#{protocol}://#{host}#{path}"
        end

        # Returns url for thumbnail image.
        # @return [String] thumbnail url
        def thumbnail
          file_set = thumbnail_file_set
          return unless file_set
          thumbnail_file = file_set.thumbnail_files.try(:first)
          id = thumbnail_file.id.to_s if thumbnail_file
          return unless id
          path = url_helpers.download_path(resource_id: file_set.id.to_s, id: id)
          "#{protocol}://#{host}#{path}"
        end

        # Returns url for geo concern show page.
        # @return [String] geo concern show page url
        def to_s
          document_helper.polymorphic_url(resource_decorator, host: host, protocol: protocol)
        end

        private

          # Retrieve the default options for URL's
          # @return [Hash]
          def default_url_options
            Figgy.default_url_options
          end

          # Instantiates a DocumentHelper object.
          # Used for access to rails url_helpers and poymorphic routes.
          # @return [DocumentHelper] document helper
          def document_helper
            @helper ||= DocumentHelper.new
          end

          # Returns the first geo file set decorator attached to work.
          # @return [FileSetDecorator] geo file set decorator
          def geo_file_set
            @geo_file_set ||= begin
              members = resource_decorator.geo_members
              members.first.decorate unless members.empty?
            end
          end

          def host
            default_url_options[:host]
          end

          # Returns a map set's thumbnail file set decorator.
          # @return [FileSetDecorator] thumbnail file set decorator
          def map_set_file_set
            member_id = Array.wrap(resource_decorator.thumbnail_id).first
            return unless member_id
            file_set = query_service.find_by(id: member_id)
            file_set.decorate if file_set && file_set.is_a?(FileSet)
          rescue Valkyrie::Persistence::ObjectNotFoundError
            nil
          end

          # Returns the first metadata file set attached to work.
          # @return [FileSetDecorator] metadata file set decorator
          def metadata_file_set(format)
            valid_members = resource_decorator.geo_metadata_members.select do |m|
              term = ControlledVocabulary.for(:geo_metadata_format).find(m.mime_type.first)
              next unless term
              term.label == format
            end
            valid_members.first unless valid_members.empty?
          end

          def protocol
            default_url_options[:protocol] || "http"
          end

          def query_service
            Valkyrie.config.metadata_adapter.query_service
          end

          # Returns a resource's thumbnail file set decorator.
          # @return [FileSetDecorator] thumbnail file set decorator
          def thumbnail_file_set
            return map_set_file_set if resource_decorator.try(:map_set?)
            geo_file_set
          end

          def url_helpers
            Valhalla::Engine.routes.url_helpers
          end
      end
    end
  end
end
