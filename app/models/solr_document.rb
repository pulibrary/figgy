# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
  # Add the routes/views for JSON-LD of documents.
  use_extension(LinkedData)

  def resource
    @resource ||= Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_by(id: id)
  end

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end

  def wayfinder
    @wayfinder ||= Wayfinder.for(resource)
  end
end
