# frozen_string_literal: true
module LinkedData
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
      resource.respond_to?(:uri) ? embedded_resource(resource) : RDF::URI(resource).as_json
    end
    alias without_context as_json

    def embedded_resource(resource)
      {
        "@id" => helper.url_for(resource),
        "@type" => "skos:Concept",
        "pref_label" => resource.label,
        "exact_match" => {
          "@id" => resource.uri
        }
      }
    end

    def helper
      ManifestBuilder::ManifestHelper.new
    end
  end
end
