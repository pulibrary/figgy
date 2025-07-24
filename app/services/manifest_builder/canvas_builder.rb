# frozen_string_literal: true
class ManifestBuilder
  class CanvasBuilder < IIIFManifest::ManifestBuilder::CanvasBuilder
    def apply_record_properties
      super
      canvas["local_identifier"] = record.local_identifier.first if record.try(:local_identifier).present?
      canvas["viewingHint"] = record.viewing_hint.first if record.try(:viewing_hint).present?
      rendering_builder.new(record).apply(canvas)
    end

    def apply(sequence)
      return sequence if record.resource.mime_type.include?("application/pdf") && record.resource.derivative_partial_files.empty?
      super
    end

    def rendering_builder
      ManifestBuilder::CanvasRenderingBuilder
    end
  end
end
