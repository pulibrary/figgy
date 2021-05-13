# frozen_string_literal: true

module Aspace
  class ArchivalObject
    attr_reader :source
    def initialize(source)
      @source = source
    end

    def repository_id
      source["repository"]["ref"].split("/").last
    end

    def uri
      source["uri"]
    end

    # TODO: Implement this. It should check instances for digital objects which
    # correspond to the given figgy manifest.
    def manifest?(source_metadata_identifier:)
      false
    end
  end
end
