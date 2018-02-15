# frozen_string_literal: true
module GeoResources
  module Discovery
    class DocumentBuilder
      class DocumentPath
        attr_reader :resource_decorator
        def initialize(resource_decorator)
          @resource_decorator = resource_decorator
        end

        # Returns url for downloading the original file.
        # @return [String] original file download url
        def file_download
          @file_set = file_set
          return unless @file_set
          id = @file_set.original_file.id.to_s
          path = url_helpers.download_path(resource_id: @file_set.id.to_s, id: id)
          "#{protocol}://#{host}#{path}"
        end

        # Returns url for downloading the metadata file.
        # @param [String] metadata file format to download
        # @return [String] metadata download url
        def metadata_download(format)
          @metadata_file_set = metadata_file_set(format)
          return unless @metadata_file_set
          id = @metadata_file_set.original_file.id.to_s
          path = url_helpers.download_path(resource_id: @metadata_file_set.id.to_s, id: id)
          "#{protocol}://#{host}#{path}"
        end

        # Returns url for thumbnail image.
        # @return [String] thumbnail url
        def thumbnail
          @file_set = file_set
          return unless @file_set
          thumbnail_file = @file_set.thumbnail_files.try(:first)
          id = thumbnail_file.id.to_s if thumbnail_file
          return unless id
          path = url_helpers.download_path(resource_id: @file_set.id.to_s, id: id)
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
          # @return [FileSetPresenter] geo file set decorator
          def file_set
            members = resource_decorator.geo_members
            members.first.decorate unless members.empty?
          end

          def host
            default_url_options[:host]
          end

          # Returns the first metadata file set attached to work.
          # @return [FileSetPresenter] metadata file set
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

          def url_helpers
            Valhalla::Engine.routes.url_helpers
          end
      end
    end
  end
end
