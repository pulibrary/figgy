# frozen_string_literal: true
class DspaceCollectionIngester < DspaceIngester
  def resource_type
    "collection"
  end

  def resource_path
    "/collections/#{id}"
  end

  def resource
    headers = request_headers("Accept" => "application/json")
    request_resource(path: resource_path, headers: headers)
  end

  def request_items_path
    "collections/#{id}/items"
  end

  def request_items(headers: {}, **params)
    paginated_request(path: request_items_path, headers: headers, **params)
  end

  def children
    data = []

    loop do
      headers = request_headers("Accept" => "application/json")
      new_data = yield(headers: headers, offset: data.length) if block_given?
      break if new_data.empty?
      data.concat(new_data)

      break if new_data.count < DSPACE_PAGE_SIZE
    end
    data
  end

  def items
    @items ||= children(&method(:request_items))
  end

  def title
    @title ||= begin
                 return unless resource.key?("name")
                 resource["name"]
               end
  end

  def ingest_items(**attrs)
    items.each do |item|
      item_handle = item["handle"]
      logger.info "Preparing to ingest the member Item #{item_handle}..."
      item_ingester = DspaceIngester.new(handle: item_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      item_ingester.id = item["id"]
      item_ingester.ingest!(**attrs)
    end
  end

  def persist_collection_resource
    collection = Collection.new
    collection_change_set = CollectionChangeSet.new(collection)
    collection_change_set.validate(title: title, slug: handle.parameterize)
    change_set_persister = ChangeSetPersister.default
    change_set_persister.save(change_set: collection_change_set)
  end

  def ingest!(**attrs)
    logger.info("Ingesting DSpace collection #{id}...")

    unless attrs.key?(:member_of_collection_ids)
      attrs[:member_of_collection_ids] = []
    end
    persisted = persist_collection_resource
    attrs[:member_of_collection_ids].append(persisted.id.to_s)

    unless attrs.key?(:local_identifier)
      attrs[:local_identifier] = []
    end
    attrs[:local_identifier].append(title)

    ingest_items(**attrs)
  end
end
