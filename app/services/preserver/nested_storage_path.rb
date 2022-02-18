# frozen_string_literal: true

class Preserver
  class NestedStoragePath
    attr_reader :base_path
    def initialize(base_path:)
      @base_path = base_path
    end

    def generate(resource:, file:, original_filename:)
      raise ArgumentError, "original_filename must be provided" unless original_filename
      Pathname.new(base_path).join(*nested_path(resource)).join(original_filename)
    end

    def nested_path(resource)
      parent = Wayfinder.for(resource).try(:parent)
      return(nested_path(parent) + ["data", resource.id.to_s]) if parent
      [resource.id.to_s]
    end
  end
end
