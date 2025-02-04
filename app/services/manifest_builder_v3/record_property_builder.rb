# frozen_string_literal: true
class ManifestBuilderV3
  # this class was added to support viewingDirection. Should be deleted once
  # we upgrade to a release with the resolution to
  # https://github.com/samvera-labs/iiif_manifest/issues/12
  class RecordPropertyBuilder < IIIFManifest::V3::ManifestBuilder::RecordPropertyBuilder
    def apply(manifest)
      manifest = super
      manifest.viewing_direction = viewing_direction if viewing_direction.present? && manifest.respond_to?(:viewing_direction=)
      manifest.behavior = behavior
      if record.resource.downloadable == ["none"]
        manifest["service"] ||= []
        manifest["service"] << uv_disable_download_service
      end

      manifest
    end

    delegate :resource, to: :record

    private

      # Works with our current UV setup, but doesn't work
      # with Clover or newer versions of UV
      def uv_disable_download_service
        {
          "@context" => "https://universalviewer.io/context.json",
          "id" => "https://universalviewer.io/ui-extensions-profile#disableUI",
          "type" => "UVExtensionService",
          "profile" => "https://universalviewer.io/ui-extensions-profile",
          "disableUI" => ["mediaDownload"]
        }
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
