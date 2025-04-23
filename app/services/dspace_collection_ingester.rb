# frozen_string_literal: true
class DspaceCollectionIngester < DspaceIngester
  attr_reader :parent, :member_of_collection_ids, :local_identifiers

  def self.default_resource_types
    [
      "collection"
    ]
  end

  def title
    @title ||= begin
                 return unless resource.key?("name")
                 resource["name"]
               end
  end

  def ingest!(**attrs)
    logger.info("Ingesting DSpace collection #{id}...")

    ingest_items(**attrs)
  end

  def initialize(parent: nil, limit: nil, **options)
    super(**options)

    @parent = parent

    @limit = limit
    @limit = limit.to_i unless limit.nil?
  end

  private

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
    rescue => error
      Rails.logger.warn(error)
      []
    end

    def children
      data = []

      loop do
        headers = request_headers("Accept" => "application/json")
        new_data = yield(headers: headers, offset: data.length) if block_given?
        break if new_data.empty?
        data.concat(new_data)

        break if new_data.count < @page_size
      end

      data
    end

    def items
      @items ||= children(&method(:request_items))
    end

    def ingest_items(**attrs)
      items.each_with_index do |item, index|
        unless @limit.nil?
          if index >= @limit
            @limit = 0
            break
          end
        end

        item_handle = item["handle"]
        logger.info("Enqueuing the job to ingest the member Item #{item_handle}...")

        IngestDspaceAssetJob.perform_later(
          handle: item_handle,
          dspace_api_token: @dspace_api_token,
          ingest_service_klass: DspaceIngester,
          limit: @limit,
          delete_preexisting: @delete_preexisting,
          **attrs
        )
      end
    end
end
