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
      return if image_file_sets.empty?
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

      def sibling_file_sets
        @sibling_file_sets ||= record.parent_node.decorate.try(:file_sets) || []
      end

      def image_file_sets
        @image_file_sets ||= sibling_file_sets.select(&:image?)
      end

      def image_record
        return nil if image_file_sets.empty?
        ManifestBuilderV3::LeafNode.new(image_file_sets.first, record)
      end
  end
end
