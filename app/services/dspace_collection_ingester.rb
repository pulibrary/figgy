# frozen_string_literal: true
class DspaceCollectionIngester < DspaceIngester
  def request_items(offset: 0, headers: {})
    path = "/collections/#{id}/items"
    params = {
      offset: offset,
      limit: DSPACE_PAGE_SIZE
    }

    # I am not certain why this needed
    response = Faraday.get(@rest_base_url + path, **params, **headers)
    JSON.parse(response.body)
  end

  def items
    @items ||= begin
                      data = []

                      loop do
                        headers = {}
                        headers["rest-dspace-token"] = @dspace_api_token unless @dspace_api_token.nil?
                        # "Accept: application/json
                        headers["Accept"] = "application/json"
                        new_data = request_items(offset: data.length, headers: headers)
                        data.concat(new_data) unless new_data.empty?

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def ingest!
    raise(StandardError, "Failed to retrieve member Items for #{ark}. Perhaps you require an authentication token?") if items.empty?

    items.each do |item|
      item_handle = item["handle"]
      logger.info "Preparing to ingest the member Item #{item_handle}..."
      item_ingester = DspaceIngester.new(handle: item_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      item_ingester.id = item["id"]
      item_ingester.ingest!
    end
  end
end
