# frozen_string_literal: true

class ManifestBuilder
  # this class was added to support viewingDirection. Should be deleted once
  # we upgrade to a release with the resolution to
  # https://github.com/samvera-labs/iiif_manifest/issues/12
  class RecordPropertyBuilder < IIIFManifest::ManifestBuilder::RecordPropertyBuilder
    def apply(manifest)
      manifest = super
      manifest.viewing_direction = viewing_direction if viewing_direction.present? && manifest.respond_to?(:viewing_direction=)
      manifest["manifests"] ||= [] if record.is_a?(IIIFManifest::IIIFCollection)
      manifest
    end

    private

      def viewing_direction
        (record.respond_to?(:viewing_direction) && record.send(:viewing_direction))
      end
  end
end
