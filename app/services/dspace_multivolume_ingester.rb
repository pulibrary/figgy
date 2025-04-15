# frozen_string_literal: true
class DspaceMultivolumeIngester < DspaceCollectionIngester
  def ingest_items(**attrs)
    persisted = []

    items.each_with_index do |item, index|
      unless @limit.nil?
        if index >= @limit
          @limit = 0
          break
        end
      end
      item_attrs = attrs.dup

      item_handle = item["handle"]
      logger.info "Preparing to ingest the member Item #{item_handle}..."
      item_ingester = DspaceIngester.new(handle: item_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      item_ingester.id = item["id"]
      resource = item_ingester.ingest_now!(**item_attrs)
      persisted.append(resource)
    end

    persisted.flatten
  end

  def persist_collection_resource
    collection = Collection.new
    collection_change_set = CollectionChangeSet.new(collection)
    collection_change_set.validate(title: title, slug: handle.parameterize)
    change_set_persister = ChangeSetPersister.default
    change_set_persister.save(change_set: collection_change_set)
  end

  def change_set_persister
    ChangeSetPersister.default
  end

  def persist_resource(**attrs)
    resource = ScannedResource.new
    resource_change_set = change_set.new(resource)
    raise("Invalid attributes: #{resource_change_set.errors.full_messages.to_sentence}") unless resource_change_set.validate(**attrs)

    change_set_persister.save(change_set: resource_change_set)
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end

  def find_or_persist_resource(**attrs)
    results = query_service.custom_queries.find_many_by_property(property: :identifier, values: [ark])
    persisted = results.last
    return persisted unless persisted.nil?

    persist_resource(**attrs)
  end

  def ingest!(**attrs)
    logger.info("Ingesting DSpace collection #{id} as a multi-volume Work...")

    attrs[:member_of_collection_ids] = @collection_ids
    raise("A parent Collection is required for #{id}") if attrs[:member_of_collection_ids].empty?

    persisted = ingest_items(**attrs)
    member_ids = persisted.map { |m| m.id.to_s }
    raise("Empty member_ids for #{id}") if member_ids.empty?

    attrs[:member_ids] = member_ids

    @title = rest_resource["name"]
    @publisher = @title
    attrs[:title] = @title
    attrs[:source_metadata_identifier] = source_metadata_identifier

    persisted = find_or_persist_resource(**attrs)
    persisted
  end
end
