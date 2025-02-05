# frozen_string_literal: true
class ManifestBuilderV3
  # Adds posterCanvas element for compatibility with older UV.
  # Remove this class once we upgrade UV or migrate to another viewer.
  class PosterCanvasBuilder
    attr_reader :record
    # Constructor
    # @param record [ManifestBuilder::LeafNode, FileSet]
    def initialize(record)
      @record = record
    end

    # Add posterCanvas element if accompanying image file set exists
    # @param manifest [IIIFManifest::ManifestBuilder::IIIFManifest::Canvas]
    def apply(manifest)
      return unless record.av_manifest? && record.respond_to?(:resource)
      return if poster_image_record.nil?
      manifest["posterCanvas"] = poster_canvas
    end

    private

      def poster_canvas
        canvas_builder.new(poster_image_record, record).canvas
      end

      def canvas_builder
        ManifestBuilderV3::ManifestServiceLocator.canvas_builder
      end

      def poster_image_record
        @poster_image_record ||= begin
                                   return nil unless image_file_set
                                   LeafNode.new(image_file_set, record)
                                 end
      end

      def image_file_set
        return nil if image_file_sets.empty? && member_image_file_sets.empty?
        if !image_file_sets.empty?
          image_file_sets.first
        else
          member_image_file_sets.first
        end
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

      def file_sets
        return [] unless decorated.respond_to?(:file_sets)
        decorated.file_sets
      end

      def decorated
        record.resource.decorate
      end
  end
end
