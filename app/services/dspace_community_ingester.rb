# frozen_string_literal: true
class DspaceCommunityIngester < DspaceCollectionIngester
  def resource_type
    "community"
  end

  def request_communities(headers: {}, **params)
    path = "communities/#{id}/communities"

    paginated_request(path: path, headers: headers, **params)
  end

  def request_collections(headers: {}, **params)
    path = "communities/#{id}/collections"

    paginated_request(path: path, headers: headers, **params)
  end

  def request_items_path
    "communities/#{id}/items"
  end

  def communities
    @communities ||= children(&method(:request_communities))
  end

  def collections
    @collections ||= children(&method(:request_collections))
  end

  def ingest!(**attrs)
    logger.info("Ingesting DSpace community #{id}...")

    communities.each do |community|
      comm_handle = community["handle"]
      ingester = DspaceCommunityIngester.new(handle: comm_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      ingester.id = community["id"]
      ingester.ingest!(**attrs)
    end

    collections.each do |collection|
      collec_handle = collection["handle"]
      ingester = DspaceCollectionIngester.new(handle: collec_handle, logger: @logger, dspace_api_token: @dspace_api_token)
      # Reduces the number of API requests
      ingester.id = collection["id"]
      ingester.ingest!(**attrs)
    end

    ingest_items(**attrs)
  end
end
