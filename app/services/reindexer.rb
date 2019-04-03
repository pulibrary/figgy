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
    wipe_records if wipe
    logger.info "Reindexing all records"
    progress_bar
    index_individually = []
    all_resources.each_slice(batch_size) do |records|
      begin
        solr_adapter.persister.save_all(resources: records)
        progress_bar.progress += records.count
      rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http
        index_individually += records
      end
    end
    index_individually.each { |record| single_index(record, progress_bar) }
    logger.info "Done"
  end

  def wipe_records
    logger.info "Clearing Solr"
    solr_adapter.persister.wipe!
  end

  def single_index(record, progress_bar)
    solr_adapter.persister.save(resource: record)
    progress_bar.progress += 1
  rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http
    logger.error("Could not index #{record.id}")
    Honeybadger.notify("Could not index #{record.id}")
  end

  def blacklisted_models
    [
      ProcessedEvent
    ]
  end

  def progress_bar
    @progress_bar ||= ProgressBar.create format: "%a %e %P% Processed: %c from %C", total: total
  end

  def all_resources
    query_service.custom_queries.memory_efficient_all(except_models: blacklisted_models)
  end

  def total
    query_service.resources.count
  end
end
