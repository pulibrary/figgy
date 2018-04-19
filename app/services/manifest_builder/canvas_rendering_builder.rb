# frozen_string_literal: true
class ManifestBuilder
  class CanvasRenderingBuilder
    attr_reader :record
    def initialize(record)
      @record = record
    end

    def apply(manifest)
      return unless record.try(:ocr_content).present?
      manifest["rendering"] ||= []
      manifest["rendering"] << {
        "@id" => helper.polymorphic_url([:text, record]),
        "format" => "text/plain",
        "label" => "Download page text"
      }
    end

    def helper
      @helper || ManifestBuilder::ManifestHelper.new
    end
  end
end
