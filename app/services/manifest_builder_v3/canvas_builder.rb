# frozen_string_literal: true
class ManifestBuilderV3
  class CanvasBuilder < IIIFManifest::V3::ManifestBuilder::CanvasBuilder
    def apply_record_properties
      super
      canvas["local_identifier"] = record.local_identifier.first if record.try(:local_identifier).present?
      canvas["viewingHint"] = record.viewing_hint.first if record.try(:viewing_hint).present?
      canvas["thumbnail"] = build_thumbnail_values
      rendering_builder.new(record).apply(canvas)
      accompanying_canvas_builder.new(record).apply(canvas)
    end

    def apply(sequence)
      return sequence if record.resource.mime_type.include?("application/pdf")
      super
    end

    def rendering_builder
      ManifestBuilderV3::CanvasRenderingBuilder
    end

    def accompanying_canvas_builder
      ManifestBuilderV3::AccompanyingCanvasBuilder
    end

    def label
      return record.structure.label if record.respond_to?(:structure)
      record.try(:label)
    end

    private

      def build_thumbnail_values
        [
          {
            "id" => helper.manifest_image_thumbnail_path(record.resource),
            "type" => "Image",
            "format" => "image/jpeg",
            "width" => 200
          }
        ]
      rescue
        nil
      end

      def helper
        @helper ||= ManifestHelper.new
      end
  end
end
