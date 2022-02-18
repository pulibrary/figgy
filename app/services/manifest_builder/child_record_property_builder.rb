# frozen_string_literal: true

class ManifestBuilder
  class ChildRecordPropertyBuilder
    attr_reader :record, :path
    def initialize(record)
      @record = record
    end

    def apply(manifest)
      manifest["@id"] = record.manifest_url.to_s
      manifest.label = record.to_s
      manifest.description = record.description
      manifest
    end
  end
end
