# frozen_string_literal: true
class DspaceCollectionIngester < DspaceIngester
  def resource_type
    "collection"
  end

  def request_items_path
    "collections/#{id}/items"
  end

  def request_items(headers: {}, **params)
    paginated_request(path: request_items_path, headers: headers, **params)
  end

  def items
    @items ||= begin
                      data = []

                      loop do
                        headers = request_headers("Accept" => "application/json")
                        new_data = request_items(offset: data.length, headers: headers)
                        break if new_data.empty?
                        data.concat(new_data)

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def ingest_items
    items.each do |item|
      item_handle = item["handle"]
      logger.info "Preparing to ingest the member Item #{item_handle}..."
      item_ingester = DspaceIngester.new(handle: item_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      item_ingester.id = item["id"]
      item_ingester.ingest!
    end
  end

  def ingest!
    logger.info("Ingesting DSpace collection #{id}...")

    ingest_items
  end
end
