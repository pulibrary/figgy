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
          {"@context" => "http://universalviewer.io/context.json", "profile" => "http://universalviewer.io/ui-extensions-profile", "disableUI" => ["mediaDownload"]}
        ]
      end

      manifest["posterCanvas"] = poster_canvas_builder.canvas unless poster_image_record.nil?
      manifest
    end

    delegate :resource, to: :record

    private

      def decorated
        resource.decorate
      end

      def file_sets
        return [] unless decorated.respond_to?(:file_sets)
        decorated.file_sets
      end

      def image_file_sets
        file_sets.select(&:image?)
      end

      def member_image_file_sets
        return [] unless decorated.respond_to?(:volumes)

        values = decorated.volumes.map(&:file_sets)
        values.flatten!
        values.select(&:image?)
      end

      def poster_image_record
        return nil if image_file_sets.empty? && member_image_file_sets.empty?

        image_file_set = if !image_file_sets.empty?
          image_file_sets.first
        else
          member_image_file_sets.first
        end

        ManifestBuilder::LeafNode.new(image_file_set, record)
      end

      def poster_canvas_builder
        canvas_builder_factory.canvas_builder_factory.new(poster_image_record, record)
      end

      def viewing_direction
        (record.respond_to?(:viewing_direction) && record.send(:viewing_direction))
      end
  end
end
