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
      def build_range
        super
        range["items"] =
          canvas_builders.collect do |cb|
            {
              "type" => "Canvas",
              "id" => "#{cb.path}#t=0,#{duration(cb)}",
              "label" => cb.label
            }
          end
      end

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

      def duration(canvas_builder)
        proxy_id = canvas_builder.record.structure.proxy.first
        file_set_presenter = parent.file_set_presenters.find { |x| x.id == proxy_id.to_s }
        file_set_presenter&.display_content&.duration
      end

      def label(canvas_builder)
        proxy_id = canvas_builder.record.structure.proxy.first
        file_set_presenter = parent.file_set_presenters.find { |x| x.id == proxy_id.to_s }
        file_set_presenter&.display_content&.label
      end
    end
  end
end
