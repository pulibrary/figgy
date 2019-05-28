# frozen_string_literal: true
class ManifestBuilder
  # this class was added to support viewingDirection. Should be deleted once
  # we upgrade to a release with the resolution to
  # https://github.com/samvera-labs/iiif_manifest/issues/12
  class RecordPropertyBuilderV3 < IIIFManifest::V3::ManifestBuilder::RecordPropertyBuilder
    def apply(manifest)
      manifest = super
      manifest.viewing_direction = viewing_direction if viewing_direction.present? && manifest.respond_to?(:viewing_direction=)
      manifest.behavior = ["auto-advance"]
      if record.resource.downloadable == ["none"]
        manifest["service"] = [
          { "@context" => "http://universalviewer.io/context.json", "profile" => "http://universalviewer.io/ui-extensions-profile", "disableUI" => ["mediaDownload"] }
        ]
      end
      manifest
    end

    private

      def viewing_direction
        (record.respond_to?(:viewing_direction) && record.send(:viewing_direction))
      end
  end
end
