# frozen_string_literal: true
class DspaceCollectionIngester < DspaceIngester
  def request_resource(path:, params: {}, headers: {})
    uri = URI.parse(@rest_base_url.to_s + path)

    response = Faraday.get(uri, params, headers)
    return [] if response.status == 404

    JSON.parse(response.body)
  end

  def paginated_request(path:, headers: {}, offset: 0, **params)
    default_params = {
      offset: offset,
      limit: DSPACE_PAGE_SIZE
    }
    request_params = default_params.merge(params)

    request_resource(path: path, params: request_params, headers: headers)
  end

  def request_items_path
    "collections/#{id}/items"
  end

  def request_items(headers: {}, **params)
    paginated_request(path: request_items_path, headers: headers, **params)
  end

  def request_headers(**options)
    headers = options
    headers["rest-dspace-token"] = @dspace_api_token unless @dspace_api_token.nil?

    headers
  end

  def id
    @id ||= begin
              path = "handle/#{ark}"
              headers = request_headers(Accept: "application/json")
              resource = request_resource(path: path, headers: headers)

              return unless resource.key?("id")
              resource["id"]
            end
  end

  def items
    @items ||= begin
                      data = []

                      loop do
                        headers = request_headers(Accept: "application/json")
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
