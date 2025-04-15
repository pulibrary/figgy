# frozen_string_literal: true
class DspaceMVWIngester < DspaceCollectionIngester

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

    persisted
  end

  def ingest!(**attrs)
    logger.info("Ingesting DSpace collection #{id} as a multi-volume Work...")

    attrs[:member_of_collection_ids] = @collection_ids
    raise("A parent Collection is required for #{id}") if attrs[:member_of_collection_ids].empty?

    # This was disabled
    # persisted = find_or_persist
    # attrs[:member_of_collection_ids].append(persisted.id.to_s)

    @local_identifiers.append(formatted_title)
    @local_identifiers = [] if @local_identifiers.length == 1 && @local_identifiers.first == title

    if attrs.key?(:local_identifier)
      attrs[:local_identifier] += @local_identifiers
    else
      attrs[:local_identifier] = @local_identifiers
    end

    persisted = ingest_items(**attrs)
    member_ids = persisted.map { |m| m.id.to_s }
    raise("Empty member_ids for #{id}") if member_ids.empty?
    attrs[:member_ids] = member_ids

    item_handle = item["handle"]
    logger.info "Preparing to ingest the member Item #{item_handle}..."
    parent_ingester = DspaceIngester.new(handle: item_handle, logger: @logger, dspace_api_token: @dspace_api_token)
    parent_ingester.ingest!(**attrs)
  end
end

