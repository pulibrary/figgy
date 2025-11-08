# frozen_string_literal: true
class FilesetFallbackRepository < Blacklight::Solr::Repository
  def find(id, params)
    super
  rescue Blacklight::Exceptions::RecordNotFound
    # It might be a FileSet, so fall back if so.
    resource = ChangeSetPersister.default.query_service.find_by(id: id)
    doc = Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: resource).to_h
    # Gonna try not having any solr response...
    OpenStruct.new(documents: [SolrDocument.new(doc)])
  end
end
