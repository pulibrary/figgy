# frozen_string_literal: true
class LinkedResourceBuilder
  class LinkedNode
    attr_reader :resource

    def initialize(resource:)
      @resource = resource
    end

    def self.new(resource:)
      if resource.respond_to?(:uri) || resource.to_s =~ /^https?\:/
        super(resource: resource)
      else
        Literal.new(value: resource)
      end
    end

    def as_json
      resource.respond_to?(:uri) ? RDF::URI(Array.wrap(resource.uri).first).as_json : RDF::URI(resource).as_json
    end
    alias without_context as_json
  end
end
