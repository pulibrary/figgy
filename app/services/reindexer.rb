# frozen_string_literal: true

class Reindexer
  def self.reindex_all(logger: Logger.new($stdout), wipe: false, batch_size: 500, solr_adapter: :index_solr)
    new(
      solr_adapter: Valkyrie::MetadataAdapter.find(solr_adapter),
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
      logger: logger,
      wipe: wipe,
      batch_size: batch_size
    ).reindex_all
  end

  def self.reindex_works(logger: Logger.new($stdout), wipe: false, batch_size: 500, solr_adapter: :index_solr)
    new(
      solr_adapter: Valkyrie::MetadataAdapter.find(solr_adapter),
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
      logger: logger,
      wipe: wipe,
      batch_size: batch_size
    ).reindex_works
  end

  attr_reader :solr_adapter, :query_service, :logger, :wipe, :batch_size
  def initialize(solr_adapter:, query_service:, logger:, wipe: false, batch_size: 500)
    @solr_adapter = solr_adapter
    @query_service = query_service
    @logger = logger
    @wipe = wipe
    @batch_size = batch_size
  end

  def reindex_all(except_models: excluded_models)
    wipe_records if wipe
    logger.info "Reindexing all records (except #{except_models.to_sentence})"
    FilteredIndexer.new(indexer: self, except_models: except_models).index!
    logger.info "Done"
  end

  def reindex_works
    reindex_all(except_models: excluded_models + ["FileSet", "PreservationObject"])
  end

  def wipe_records
    logger.info "Clearing Solr"
    solr_adapter.persister.wipe!
  end

  def excluded_models
    IndexingAdapter.no_index_models
  end

  class FilteredIndexer
    attr_reader :indexer, :except_models
    delegate :solr_adapter, :query_service, :logger, :batch_size, to: :indexer
    def initialize(indexer:, except_models:)
      @indexer = indexer
      @except_models = except_models
    end

    def index!
      progress_bar
      index_individually = []
      all_resources.each_slice(batch_size) do |records|
        multi_index_persist(records)
        progress_bar.progress += records.count
      rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http
        index_individually += records
      end
      run_individual_retries(index_individually)
      solr_adapter.connection.commit
    end

    def run_individual_retries(records)
      logger.info "Reindexing #{records.count} individually due to errors during batch indexing"
      records.each { |record| single_index(record) }
    end

    def single_index(record)
      single_index_persist(record)
      progress_bar.progress += 1
    rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
      logger.error("Could not index #{record.id} due to #{e.class}")
      Honeybadger.notify(e, context: {record_id: record.id})
    end

    def multi_index_persist(records)
      solr_adapter.persister.save_all(resources: records)
    end

    def single_index_persist(record)
      solr_adapter.persister.save(resource: record, external_resource: true)
    end

    def progress_bar
      @progress_bar ||= ProgressBar.create format: "%a %e %P% Processed: %c from %C", total: total
    end

    def all_resources
      query_service.custom_queries.memory_efficient_all(except_models: except_models)
    end

    def total
      query_service.custom_queries.count_all_except_models(except_models: except_models)
    end
  end
end
