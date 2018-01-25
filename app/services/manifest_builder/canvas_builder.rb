# frozen_string_literal: true
class ManifestBuilder
  class CanvasBuilder < IIIFManifest::ManifestBuilder::CanvasBuilder
    def apply_record_properties
      super
      canvas['local_identifier'] = record.local_identifier.first if record.try(:local_identifier).present?
    end
  end
end
