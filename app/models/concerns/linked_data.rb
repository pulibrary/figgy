# frozen_string_literal: true

# Enables RDF views of Solr Documents. Included via
# `SolrDocument.use_extension`.
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

  # @return [String] JSON-LD representation of the resource.
  # @see LinkedData::LinkedResource#to_jsonld
  def export_as_jsonld
    resource.linked_resource.to_jsonld
  end

  def export_as_nt
    RDF::Graph.new.from_jsonld(export_as_jsonld).dump(:ntriples)
  end

  def export_as_ttl
    RDF::Graph.new.from_jsonld(export_as_jsonld).dump(:ttl)
  end
end
