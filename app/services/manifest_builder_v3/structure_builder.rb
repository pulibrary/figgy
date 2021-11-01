# frozen_string_literal: true
class ManifestBuilderV3
  class StructureBuilder < IIIFManifest::V3::ManifestBuilder::StructureBuilder
    def range_builder(top_range)
      RangeBuilder.new(
        top_range,
        record, true,
        canvas_builder_factory: canvas_builder_factory,
        iiif_range_factory: iiif_range_factory
      )
    end

    class RangeBuilder < IIIFManifest::V3::ManifestBuilder::RangeBuilder
      def sub_ranges
        @sub_ranges ||= [] unless record.respond_to?(:ranges)
        @sub_ranges ||= record.ranges.map do |sub_range|
          RangeBuilder.new(
            sub_range,
            parent,
            canvas_builder_factory: canvas_builder_factory,
            iiif_range_factory: iiif_range_factory
          )
        end
      end
    end
  end
end
