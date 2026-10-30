class ManifestBuilderV3
  class CanvasBuilder < IIIFManifest::V3::ManifestBuilder::CanvasBuilder
    def apply_record_properties
      super
      canvas["local_identifier"] = record.local_identifier.first if record.try(:local_identifier).present?
      canvas["viewingHint"] = record.viewing_hint.first if record.try(:viewing_hint).present?
      thumbnail = build_thumbnail_values
      canvas["thumbnail"] = thumbnail if thumbnail
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
        return unless thumbnail_resource
        [
          {
            "id" => helper.manifest_image_thumbnail_path(thumbnail_resource),
            "type" => "Image",
            "format" => "image/jpeg",
            "width" => 200
          }
        ]
      rescue
        nil
      end

      # Audio and video FileSets have no image derivatives, so use an image
      # FileSet from their parent resource (e.g. a scan of the tape) instead.
      def thumbnail_resource
        @thumbnail_resource ||=
          record.resource.to_model.try(:av?) ? record.try(:av_image_file_set) : record.resource
      end

      def helper
        @helper ||= ManifestHelper.new
      end
  end
end
