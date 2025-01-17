# frozen_string_literal: true
class DspaceCommunityIngester < DspaceCollectionIngester
  def request_communities(headers: {}, **params)
    path = "/communities/#{id}/communities"

    paginated_request(path: path, headers: headers, **params)
  end

  def request_collections(headers: {}, **params)
    path = "/communities/#{id}/collections"

    paginated_request(path: path, headers: headers, **params)
  end

  def communities
    @communities ||= begin
                      data = []

                      loop do
                        headers = request_headers(Accept: "application/json")
                        new_data = request_communities(headers: headers, offset: data.length)
                        break if new_data.empty?
                        data.concat(new_data)

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def collections
    @collections ||= begin
                      data = []

                      loop do
                        headers = request_headers(Accept: "application/json")
                        new_data = request_collections(headers: headers, offset: data.length)
                        break if new_data.empty?
                        data.concat(new_data)

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def ingest!
    logger.info("Ingesting DSpace community #{id}...")
    communities.each do |community|
      comm_handle = community["handle"]
      ingester = DspaceCommunityIngester.new(handle: comm_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      ingester.id = community["id"]
      ingester.ingest!
    end

    collections.each do |collection|
      collec_handle = collection["handle"]
      ingester = DspaceCollectionIngester.new(handle: collec_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      ingester.id = collection["id"]
      ingester.ingest!
    end

    ingest_items
  end
end
