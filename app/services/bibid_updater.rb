# frozen_string_literal: true

# Service to update Voyager bibids to alma mms ids
class BibidUpdater
  def self.update(logger: Logger.new(STDOUT), batch_size: 1000)
    new(
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
      logger: logger,
      batch_size: batch_size
    ).update
  end

  attr_reader :query_service, :logger, :batch_size
  delegate :run_query, to: :query_service
  def initialize(query_service:, logger:, batch_size: 1000)
    @query_service = query_service
    @logger = logger
    @batch_size = batch_size
  end

  def update
    logger.info "Updating #{total_count} records"
    progress_bar
    (1..iterations).each do
      run_query(update_query)
      progress_bar.progress += 1
    end

    Reindexer.reindex_all
  end

  private

    def iterations
      @iterations ||= 1 + (total_count / batch_size)
    end

    def progress_bar
      @progress_bar ||= ProgressBar.create format: "%a %e %P% Batches Processed: %c of %C", total: iterations
    end

    def total_count
      @total_count ||= query_service.connection[total_count_query].first[:count]
    end

    def total_count_query
      <<-SQL
        SELECT COUNT(*)
        #{voyager_resources_query}
      SQL
    end

    def update_query
      <<-SQL
        -- Find all resources that have bibids
        WITH voyager_resources AS (
          SELECT *
          #{voyager_resources_query}
          LIMIT #{batch_size}
        )
        UPDATE orm_resources
        -- Append Alma prefix "99" and postfix "3506421" to Voyager bibid
        SET metadata = jsonb_set(orm_resources.metadata, '{source_metadata_identifier,0}', concat('"99', orm_resources.metadata -> 'source_metadata_identifier' ->> 0, '3506421"')::jsonb)
        FROM voyager_resources
        WHERE orm_resources.id = voyager_resources.id
      SQL
    end

    def voyager_resources_query
      <<-SQL
        -- Find all resources that have bibids
        FROM orm_resources a,
        jsonb_array_elements_text(a.metadata->'source_metadata_identifier') AS b(identifier)
        -- Skip records that have an Alma identifier
        WHERE NOT identifier ~ '99.*3506421'
      SQL
    end
end
