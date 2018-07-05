# frozen_string_literal: true
class Reindexer
  def self.reindex_all(logger: Logger.new(STDOUT), wipe: false)
    new(
      solr_adapter: Valkyrie::MetadataAdapter.find(:index_solr),
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
      logger: logger,
      wipe: wipe
    ).reindex_all
  end

  attr_reader :solr_adapter, :query_service, :logger, :wipe
  def initialize(solr_adapter:, query_service:, logger:, wipe: false)
    @solr_adapter = solr_adapter
    @query_service = query_service
    @logger = logger
    @wipe = wipe
  end

  def reindex_all
    if wipe
      logger.info "Clearing Solr"
      solr_adapter.persister.wipe!
    end
    logger.info "Reindexing all records"
    query_service.custom_queries.memory_efficient_all.each_slice(1000) do |records|
      logger.info "Indexing #{records.count} records"
      solr_adapter.persister.save_all(resources: records)
    end
    logger.info "Done"
  end
end
