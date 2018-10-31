# frozen_string_literal: true
class ManifestBuilder
  class RangeBuilder < IIIFManifest::V3::ManifestBuilder::RangeBuilder
    def index
      return record.root.id.to_s unless record.root.nil?

      unless record.structure.nodes.empty?
        # Only retrieve the first FileSet node
        file_set_node = record.structure.nodes.first
        file_set_proxy = file_set_node.proxy.first
        return file_set_proxy.id.to_s
      end

      super
    end

    def sub_ranges
      @sub_ranges ||= record.ranges.map do |sub_range|
        self.class.new(
          sub_range,
          parent,
          canvas_builder_factory: canvas_builder_factory,
          iiif_range_factory: iiif_range_factory
        )
      end
    end
  end

  class StructureBuilder < IIIFManifest::ManifestBuilder::StructureBuilder
    def range_builder(top_range)
      range_builder_class.new(
        top_range,
        record, true,
        canvas_builder_factory: canvas_builder_factory,
        iiif_range_factory: iiif_range_factory
      )
    end

    private

      def range_builder_class
        RangeBuilder
      end
  end
end
