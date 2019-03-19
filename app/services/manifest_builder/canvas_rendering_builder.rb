# frozen_string_literal: true
class ManifestBuilder
  class CanvasRenderingBuilder
    attr_reader :record
    # Constructor
    # @param record [ManifestBuilder::LeafNode, FileSet]
    def initialize(record)
      @record = record
    end

    # Modify the manifest for the Canvas
    # @param manifest [IIIFManifest::ManifestBuilder::IIIFManifest::Canvas]
    def apply(manifest)
      if record.try(:ocr_content).present?
        manifest["rendering"] ||= []
        manifest["rendering"] << {
          "@id" => helper.polymorphic_url([:text, record]),
          "format" => "text/plain",
          "label" => "Download page text"
        }
      end

      return unless downloadable?
      manifest["rendering"] ||= []
      manifest["rendering"] << download_hash
    end

    # Construct a helper Object
    # @return [ManifestBuilder::ManifestHelper]
    def helper
      @helper || ManifestBuilder::ManifestHelper.new
    end

    private

      # FileSet resource being presented using the IIIF Manifest
      # @return [FileSet]
      def resource
        @record.respond_to?(:resource) ? @record.resource : @record
      end

      # Determines if the resource be downloaded by the user
      # @return [Boolean]
      def downloadable?
        @record.respond_to?(:resource) || @record.is_a?(FileSet)
      end

      # Retrieve the URL options for the App.
      # @return [Hash]
      def default_url_options
        Figgy.default_url_options
      end

      # Retrieve the URL from the App. settings
      # @return [String]
      def host
        default_url_options[:host]
      end

      # Retrieve the web protocol from the App. settings
      # @return [String]
      def protocol
        default_url_options[:protocol] || "http"
      end

      # Retrieve the helper Module for the routes
      # @return [Module]
      def url_helpers
        Rails.application.routes.url_helpers
      end

      # Generate a download Hash for the FileSet and members
      # @return [Hash]
      def download_hash
        original_file = resource.original_file
        original_file_id = original_file.id.to_s
        download_url_args = { resource_id: resource.id.to_s, id: original_file_id, protocol: protocol, host: host }
        download_url = url_helpers.download_url(download_url_args)

        {
          "@id" => download_url,
          "label" => "Download the original file",
          "format" => original_file.mime_type.first
        }
      end
  end
end
