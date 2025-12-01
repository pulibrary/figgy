# frozen_string_literal: true
#
# Allow Blacklight to display a show page for a FileSet even though it isn't
# indexed.
#
# We don't index FileSets because we don't search them, but want to continue
# using the same logic we use to render the show pages for all our other models.
# This will get removed if we stop rendering show pages from the Solr index
# generally.
#
# This is configured in `catalog_controller.rb`
class FilesetFallbackRepository < Blacklight::Solr::Repository
  def find(id, params)
    super
  rescue Blacklight::Exceptions::RecordNotFound
    # It might be a FileSet, so fall back if so.
    resource = ChangeSetPersister.default.query_service.find_by(id: id)
    doc = Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: resource).to_h
    # Return an object that acts like a Blacklight::Solr::Response.
    OpenStruct.new(documents: [SolrDocument.new(doc)])
  end
end
