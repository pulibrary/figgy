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
    jsonld.to_json
  end

  def export_as_nt
    RDF::Graph.new.from_jsonld(export_as_jsonld).dump(:ntriples)
  end

  def export_as_ttl
    RDF::Graph.new.from_jsonld(export_as_jsonld).dump(:ttl)
  end

  def jsonld
    imported_jsonld.merge(local_fields)
  end

  def local_fields
    {
      '@context': 'https://bibdata.princeton.edu/context.json',
      '@id': obj_url,
      identifier: resource.identifier,
      scopeNote: resource.portion_note,
      navDate: resource.nav_date,
      edm_rights: rights_object,
      memberOf: collection_objects
    }.reject { |_, v| v.nil? || v.try(:empty?) }
  end

  def rights_object
    return if resource.rights_statement.blank?
    {
      '@id': resource.rights_statement.first.to_s,
      '@type': 'dcterms:RightsStatement',
      pref_label: ControlledVocabulary.for(:rights_statement).find(resource.rights_statement.first).label
    }
  end

  def collection_objects
    return if resource.member_of_collection_ids.blank?
    collections.map do |collection|
      {
        '@id': helper.solr_document_url(id: "id-#{collection.id}"),
        '@type': 'pcdm:Collection',
        title: collection.title
      }
    end
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end

  def collections
    @collections ||= query_service.find_references_by(resource: resource, property: :member_of_collection_ids)
  end

  def obj_url
    helper.solr_document_url(id: id)
  end

  def imported_jsonld
    return basic_jsonld unless resource.primary_imported_metadata.source_jsonld.present?
    @imported_jsonld ||= JSON.parse(resource.primary_imported_metadata.source_jsonld.first)
  end

  def basic_jsonld
    {
      title: resource.title
    }
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
