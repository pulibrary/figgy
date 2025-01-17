# frozen_string_literal: true
class DspaceCommunityIngester < DspaceCollectionIngester
  def request_communities(offset: 0, headers: {})
    path = "/communities/#{id}/communities"
    params = {
      offset: offset,
      limit: DSPACE_PAGE_SIZE
    }

    response = Faraday.get(@rest_base_url + path, **params, **headers)
    return [] if response.status == 404

    JSON.parse(response.body)
  end

  def request_collections(offset: 0, headers: {})
    path = "/communities/#{id}/collections"
    params = {
      offset: offset,
      limit: DSPACE_PAGE_SIZE
    }

    response = Faraday.get(@rest_base_url + path, **params, **headers)
    return [] if response.status == 404

    JSON.parse(response.body)
  end

  def communities
    @communities ||= begin
                      data = []

                      loop do
                        headers = {}
                        headers["rest-dspace-token"] = @dspace_api_token unless @dspace_api_token.nil?
                        # "Accept: application/json
                        headers["Accept"] = "application/json"
                        new_data = request_communities(offset: data.length, headers: headers)
                        data.concat(new_data) unless new_data.empty?

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def collections
    @collections ||= begin
                      data = []

                      loop do
                        headers = {}
                        headers["rest-dspace-token"] = @dspace_api_token unless @dspace_api_token.nil?
                        # "Accept: application/json
                        headers["Accept"] = "application/json"
                        new_data = request_collections(offset: data.length, headers: headers)
                        data.concat(new_data) unless new_data.empty?

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def ingest!
    communities.each do |community|
      item_handle = community["handle"]
      logger.info "Preparing to ingest the member Item #{item_handle}..."
      item_ingester = DspaceCommunityIngester.new(handle: item_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      item_ingester.id = item["id"]
      item_ingester.ingest!
    end

    collections.each do |collection|
      item_handle = collection["handle"]
      logger.info "Preparing to ingest the member Collection #{item_handle}..."
      item_ingester = DspaceCollectionIngester.new(handle: item_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      item_ingester.id = item["id"]
      item_ingester.ingest!
    end

    super
  end
end
