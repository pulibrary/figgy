# frozen_string_literal: true
class Reindexer
  def self.reindex_all(logger: Logger.new(STDOUT))
    new(
      solr_adapter: Valkyrie::MetadataAdapter.find(:index_solr),
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
      logger: logger
    ).reindex_all
  end

  attr_reader :solr_adapter, :query_service, :logger
  def initialize(solr_adapter:, query_service:, logger:)
    @solr_adapter = solr_adapter
    @query_service = query_service
    @logger = logger
  end

  def reindex_all
    logger.info "Clearing Solr"
    solr_adapter.persister.wipe!
    logger.info "Reindexing all records"
    query_service.custom_queries.memory_efficient_all.each_slice(1000) do |records|
      logger.info "Indexing #{records.count} records"
      solr_adapter.persister.save_all(resources: records)
    end
    logger.info "Done"
  end
end
