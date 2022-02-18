# frozen_string_literal: true

class ManifestBuilder
  class SequenceBuilder < IIIFManifest::ManifestBuilder::SequenceBuilder
    attr_reader :start_canvas_builder
    def initialize(work, canvas_builder_factory:, sequence_factory:, start_canvas_builder:)
      super(work, canvas_builder_factory: canvas_builder_factory, sequence_factory: sequence_factory)
      @start_canvas_builder = start_canvas_builder
    end

    def apply(manifest)
      sequence["viewingHint"] = manifest["viewingHint"]
      start_canvas_builder.new(work).apply(sequence)
      super
    end
  end
end
