# frozen_string_literal: true

class ManifestBuilder
  class CanvasBuilderV3 < IIIFManifest::V3::ManifestBuilder::CanvasBuilder
    def apply_record_properties
      super
      canvas["local_identifier"] = record.local_identifier.first if record.try(:local_identifier).present?
      canvas["viewingHint"] = record.viewing_hint.first if record.try(:viewing_hint).present?
      rendering_builder.new(record).apply(canvas)
    end

    def rendering_builder
      ManifestBuilder::CanvasRenderingBuilder
    end

    def label
      return record.structure.label if record.respond_to?(:structure)
      record.try(:label)
    end
  end
end
