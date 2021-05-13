# frozen_string_literal: true

module Aspace
  class ArchivalObject
    attr_reader :source
    def initialize(source)
      @source = source
    end

    # TODO: Implement this. It should check instances for digital objects which
    # correspond to the given figgy manifest.
    def manifest?(source_metadata_identifier:)
      false
    end
  end
end
