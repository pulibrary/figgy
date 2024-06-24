# frozen_string_literal: true
class ManifestBuilderV3
  class CanvasRenderingBuilder < ManifestBuilder::CanvasRenderingBuilder
    # Modify the manifest for the Canvas
    # @param manifest [IIIFManifest::ManifestBuilder::IIIFManifest::Canvas]
    def apply(manifest)
      if record.try(:ocr_content).present?
        manifest["rendering"] ||= []
        manifest["rendering"] << {
          "id" => helper.polymorphic_url([:text, record]),
          "type" => "Text",
          "format" => "text/plain",
          "label" => { "en": ["download page text"] }
        }
      end

      return unless downloadable?
      manifest["rendering"] ||= []
      manifest["rendering"] << download_hash
      manifest["rendering"] += caption_downloads
      apply_geotiff_downloads(manifest)
    end

    private

      # It's important to use original_file over primary_file here so that it
      # knows to use the MP3 access download if there's no original_file.
      def original_file_hash
        return unless original_file
        original_file_id = original_file.id.to_s
        download_url_args = { resource_id: resource.id.to_s, id: original_file_id, protocol: protocol, host: host }
        download_url = url_helpers.download_url(download_url_args)

        {
          "id" => download_url,
          "format" => original_file.mime_type.first,
          "type" => "Dataset",
          "label" => { "en": ["Download the original file"] }
        }
      end
  end
end
