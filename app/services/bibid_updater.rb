# frozen_string_literal: true

# Service to update Voyager bibids to alma mms ids
class BibidUpdater
  def self.update(logger: Logger.new(STDOUT))
    new(logger: logger).update
  end

  attr_reader :logger
  def initialize(logger:)
    @logger = logger
  end

  def update
    logger.info "Updating #{total_count} records"
    progress_bar
    resources.each do |resource|
      change_set = ChangeSet.for(resource)
      change_set.source_metadata_identifier = transform_id(change_set.source_metadata_identifier)
      change_set_persister.save(change_set: change_set)
      progress_bar.progress += 1
    end
  end

  private

    def change_set_persister
      @change_set_perisister ||= ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter,
                                                        storage_adapter: Valkyrie.config.storage_adapter)
    end

    def progress_bar
      @progress_bar ||= ProgressBar.create format: "%a %e %P% Resources Processed: %c of %C", total: total_count
    end

    def query_service
      @query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
    end

    def resources
      @resources ||= query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: [], lazy: true).select do |resource|
        id = resource.source_metadata_identifier.first
        next if id =~ /99.*3506421/
        RemoteRecord.bibdata?(id)
      end
    end

    def total_count
      @total_count ||= resources.count
    end

    def transform_id(voyager_id)
      "99#{voyager_id}3506421"
    end
end
