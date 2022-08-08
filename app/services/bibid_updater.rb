# frozen_string_literal: true

# Service to update Voyager bibids to alma mms ids
class BibidUpdater
  def self.update
    new.update
  end

  def update
    progress_bar
    resources.each do |resource|
      # Reload resource to get a new version.
      resource = query_service.find_by(id: resource.id)
      resource.source_metadata_identifier = transform_id(resource.source_metadata_identifier.first)
      change_set = ChangeSet.for(resource)
      change_set_persister.save(change_set: change_set)
      progress_bar.progress += 1
    end
  end

  private

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end

    def progress_bar
      @progress_bar ||= ProgressBar.create format: "%a %e %P% Resources Processed: %c of %C", total: total_count
    end

    def query_service
      @query_service ||= change_set_persister.query_service
    end

    # We have to load everything into memory because otherwise the set runs
    # inside a transaction, which results in solr being different than postgres.
    def resources
      @resources ||=
        begin
          query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: [], lazy: true).select do |resource|
            id = resource.source_metadata_identifier.first
            next if /99.*3506421/.match?(id)
            next if transform_id(id).length > 18
            RemoteRecord.catalog?(id)
          end.to_a
        end
    end

    def total_count
      resources.size
    end

    def transform_id(voyager_id)
      "99#{voyager_id}3506421"
    end
end
