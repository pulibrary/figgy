# frozen_string_literal: true
class DspaceCommunityIngester < DspaceCollectionIngester
  def self.default_resource_types
    [
      "community"
    ]
  end

  def ingest!(**parent_attrs)
    logger.info("Ingesting DSpace community #{id}...")
    attrs = parent_attrs.dup

    attrs[:member_of_collection_ids] = @collection_ids
    raise("A parent Collection is required for #{id}") if attrs[:member_of_collection_ids].empty?

    communities.each_with_index do |community, _index|
      comm_handle = community["handle"]

      ingester = DspaceCommunityIngester.new(
        handle: comm_handle, logger: @logger, dspace_api_token: @dspace_api_token, parent: self, limit: @limit
      )
      # Reduces the number of API requests
      ingester.id = community["id"]
      ingester.ingest!
    end

    collections.each_with_index do |collection, _index|
      collec_handle = collection["handle"]

      ingester = DspaceCollectionIngester.new(
        handle: collec_handle, logger: @logger, dspace_api_token: @dspace_api_token, parent: self, limit: @limit
      )
      # Reduces the number of API requests
      ingester.id = collection["id"]
      ingester.ingest!
    end

    ingest_items(**attrs)
  end

  private

    def resource_path
      "/communities/#{id}"
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
end
