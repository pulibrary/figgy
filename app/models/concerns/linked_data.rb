# frozen_string_literal: true
module LinkedData
  def self.extended(document)
    # Register our exportable formats
    register_export_formats(document)
  end

  def self.register_export_formats(document)
    document.will_export_as(:jsonld, "application/ld+json")
    document.will_export_as(:nt, "application/n-triples")
    document.will_export_as(:ttl, "text/turtle")
  end

  def export_as_jsonld
    LinkedResourceFactory.new(resource: resource).new.to_jsonld
  end

  def export_as_nt
    RDF::Graph.new.from_jsonld(export_as_jsonld).dump(:ntriples)
  end

  def export_as_ttl
    RDF::Graph.new.from_jsonld(export_as_jsonld).dump(:ttl)
  end
end
