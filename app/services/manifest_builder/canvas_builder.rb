# frozen_string_literal: true
class ManifestBuilder
  class CanvasBuilder < IIIFManifest::ManifestBuilder::CanvasBuilder
    def apply_record_properties
      super
      canvas["local_identifier"] = record.local_identifier.first if record.try(:local_identifier).present?
      canvas["viewingHint"] = record.viewing_hint.first if record.try(:viewing_hint).present?
      canvas["thumbnail"] = build_thumbnail_values
      rendering_builder.new(record).apply(canvas)
    end

    def apply(sequence)
      return sequence if record.resource.mime_type.include?("application/pdf")
      super
    end

    def rendering_builder
      ManifestBuilder::CanvasRenderingBuilder
    end

    private

      def build_thumbnail_values
        {
          "@id" => helper.manifest_image_thumbnail_path(record.resource),
          "service" => {
            "@context" => "http://iiif.io/api/image/2/context.json",
            "@id" => helper.manifest_image_path(record.resource),
            "profile" => "http://iiif.io/api/image/2/level2.json"
          }
        }
      rescue
        nil
      end

      def helper
        @helper ||= ManifestHelper.new
      end
  end
end
