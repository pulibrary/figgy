class ManifestBuilderV3
  class AccompanyingCanvasBuilder
    attr_reader :record
    # Constructor
    # @param record [ManifestBuilder::LeafNode, FileSet]
    def initialize(record)
      @record = record
    end

    # Add accompanyingCanvas element if accompanying image file set exists
    # @param manifest [IIIFManifest::ManifestBuilder::IIIFManifest::Canvas]
    def apply(manifest)
      return unless resource.is_a?(FileSet) && resource.audio?
      return if image_file_set.nil?
      manifest["accompanyingCanvas"] = accompanying_canvas
    end

    private

      def accompanying_canvas
        canvas_builder.new(image_record, record.parent_node).canvas
      end

      def canvas_builder
        ManifestBuilderV3::ManifestServiceLocator.canvas_builder
      end

      def resource
        @record.respond_to?(:resource) ? @record.resource.to_model : @record
      end

      # Image from an audio FileSet's parent resource
      def image_file_set
        @record.try(:av_image_file_set)
      end

      def image_record
        ManifestBuilderV3::LeafNode.new(image_file_set, record)
      end
  end
end
