# frozen_string_literal: true
class Reindexer
  def self.reindex_all(logger: Logger.new(STDOUT), wipe: false, batch_size: 1000, solr_adapter: :index_solr)
    new(
      solr_adapter: Valkyrie::MetadataAdapter.find(solr_adapter),
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
      logger: logger,
      wipe: wipe,
      batch_size: batch_size
    ).reindex_all
  end

  attr_reader :solr_adapter, :query_service, :logger, :wipe, :batch_size
  def initialize(solr_adapter:, query_service:, logger:, wipe: false, batch_size: 1000)
    @solr_adapter = solr_adapter
    @query_service = query_service
    @logger = logger
    @wipe = wipe
    @batch_size = batch_size
  end

  def reindex_all
    if wipe
      logger.info "Clearing Solr"
      solr_adapter.persister.wipe!
    end
    logger.info "Reindexing all records"
    progress_bar
    query_service.custom_queries.memory_efficient_all(except_models: blacklisted_models).each_slice(batch_size) do |records|
      solr_adapter.persister.save_all(resources: records)
      progress_bar.progress += records.count
    end
    logger.info "Done"
  end

  def blacklisted_models
    [
      ProcessedEvent
    ]
  end

  def progress_bar
    @progress_bar ||= ProgressBar.create format: "%a %e %P% Processed: %c from %C", total: total
  end

  def total
    query_service.resources.all.size
  end
end
