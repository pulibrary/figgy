class ManifestBuilderV3
  # this class was added to support viewingDirection. Should be deleted once
  # we upgrade to a release with the resolution to
  # https://github.com/samvera-labs/iiif_manifest/issues/12
  class RecordPropertyBuilder < IIIFManifest::V3::ManifestBuilder::RecordPropertyBuilder
    def apply(manifest)
      manifest = super
      manifest.viewing_direction = viewing_direction if viewing_direction.present? && manifest.respond_to?(:viewing_direction=)
      manifest.behavior = behavior
      poster_canvas_builder.apply(manifest)

      manifest
    end

    delegate :resource, to: :record

    private

      def poster_canvas_builder
        PosterCanvasBuilder.new(record)
      end

      def viewing_direction
        (record.respond_to?(:viewing_direction) && record.send(:viewing_direction))
      end

      def behavior
        if record.class == ScannedMapNode
          ["individuals"]
        else
          ["auto-advance"]
        end
      end
  end
end
