# frozen_string_literal: true
class DspaceCollectionIngester < DspaceIngester
  attr_reader :parent, :collection_ids, :local_identifiers

  def resource_types
    [
      "collection"
    ]
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
      item_ingester.ingest!(**item_attrs)
    end
  end

  def prefix_patterns
    [
      /Serials and series reports (.+?) - /
    ]
  end

  def formatted_title
    unformatted = title
    formatted = unformatted
    prefix_patterns.each do |prefix_pattern|
      formatted = unformatted.gsub(prefix_pattern, "")
    end
    formatted
  end

  def ingest!(**attrs)
    logger.info("Ingesting DSpace collection #{id}...")

    attrs[:member_of_collection_ids] = @collection_ids
    raise("A parent Collection is required for #{id}") if attrs[:member_of_collection_ids].empty?

    ingest_items(**attrs)
  end

  def initialize(collection_ids: [], parent: nil, local_identifiers: [], limit: nil, **options)
    super(**options)

    @parent = parent
    @collection_ids = collection_ids
    @collection_ids += @parent.collection_ids unless @parent.nil?
    @local_identifiers = local_identifiers
    @local_identifiers += @parent.local_identifiers unless @parent.nil?
    @limit = limit
    @limit = limit.to_i unless limit.nil?
  end
end
