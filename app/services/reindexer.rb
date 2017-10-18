# frozen_string_literal: true
class Reindexer
  def self.reindex_all
    new(
      solr_adapter: Valkyrie::MetadataAdapter.find(:index_solr),
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service
    ).reindex_all
  end

  attr_reader :solr_adapter, :query_service
  def initialize(solr_adapter:, query_service:)
    @solr_adapter = solr_adapter
    @query_service = query_service
  end

  def reindex_all
    solr_adapter.persister.wipe!
    query_service.custom_queries.memory_efficient_all.each_slice(1000) do |records|
      solr_adapter.persister.save_all(resources: records)
    end
  end
end
