# frozen_string_literal: true
class DspaceIngester
  attr_reader :json_path, :logger, :handle, :ark
  attr_writer :id

  DSPACE_PAGE_SIZE = 20

  def resource_type
    "item"
  end

  def initialize(handle:, logger: Rails.logger, dspace_api_token: nil, apply_remote_metadata: true)
    @handle = handle
    @logger = logger
    @dspace_api_token = dspace_api_token

    @json_path = handle
    @ark = @handle.gsub("ark:/", "")
    @base_url = "https://dataspace.princeton.edu/"
    @rest_base_url = URI.parse(@base_url + "rest/")
    @download_base_url = URI.join(@base_url, "bitstream/", "#{ark}/")

    @apply_remote_metadata = apply_remote_metadata
    @title = nil
    @publisher = nil
  end

  def request_resource(path:, params: {}, headers: {})
    uri = URI.parse(@rest_base_url.to_s + path)
    @logger.info("Requesting #{uri} #{params}")

    response = Faraday.get(uri, params, headers)
    raise("Failed to request bibliographic metadata: #{uri} #{params} #{headers}") if response.status == 404

    JSON.parse(response.body)
  rescue StandardError => error
    Rails.logger.warn("Failed to request bibliographic metadata: #{uri} #{params} #{headers}")
    raise(error)
  end

  def paginated_request(path:, headers: {}, offset: 0, **params)
    default_params = {
      offset: offset,
      limit: DSPACE_PAGE_SIZE
    }
    request_params = default_params.merge(params)

    request_resource(path: path, params: request_params, headers: headers)
  end

  def request_headers(**options)
    headers = options
    headers["rest-dspace-token"] = @dspace_api_token unless @dspace_api_token.nil?

    headers
  end

  def id
    @id ||= begin
              path = "handle/#{ark}"
              headers = request_headers("Accept" => "application/json")
              resource = request_resource(path: path, headers: headers)

              remote_type = resource["type"]
              if remote_type != resource_type
                raise(StandardError, "Handle resolves to resource type: #{resource_type}")
              end
              return unless resource.key?("id")
              resource["id"]
            end
  end

  def request_bitstreams(headers: {}, **params)
    path = "items/#{id}/bitstreams"

    paginated_request(path: path, headers: headers, **params)
  end

  def bitstreams
    @bitstreams ||= begin
                      data = []

                      loop do
                        headers = {}
                        headers["rest-dspace-token"] = @dspace_api_token unless @dspace_api_token.nil?
                        new_data = request_bitstreams(offset: data.length, headers: headers)
                        data.concat(new_data) unless new_data.empty?

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def apply_remote_metadata?
    @apply_remote_metadata
  end

  def find_mms_by_query(query:)
    catalog_url = Figgy.config[:catalog_url]
    catalog_uri = URI.parse(catalog_url)

    catalog_base_url = "#{catalog_uri.scheme}://#{catalog_uri.host}"
    headers = {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
    conn = Faraday.new(
      url: catalog_base_url,
      headers: headers
    )

    path = "catalog.json"
    params = {
      "search_field": "all_fields",
      "q": query
    }
    response = conn.get(path, params)
    json_body = JSON.parse(response.body)

    results = json_body.fetch("data", [])
    if results.empty?
      @logger.warn("Failed to find the MMS ID using the ARK #{ark}")
      return
    end

    eportfolio_results = results.select { |result| result["attributes"].key?("electronic_portfolio_s") }
    if eportfolio_results.empty?
      @logger.warn("Failed to find the MMS ID for #{ark} with the `electronic_portfolio_s` attribute.")
      return
    end

    result = eportfolio_results.first
    raise(StandardError, "Failed to find the key 'id' in the JSON #{result}") unless result.key?("id")

    @apply_remote_metadata = query == @ark

    @source_metadata_identifier = result["id"]
    @logger.info("Successfully found the MMS ID for #{ark}: {@source_metadata_identifier}")
    @source_metadata_identifier
  end

  def publicly_visible?
    response = request_bitstreams
    !response.empty?
  end

  def source_metadata_identifier
    @source_metadata_identifier ||= find_mms_by_query(query: ark) || find_mms_by_query(query: @publisher) || find_mms_by_query(query: @title)
  end

  def default_visibility
    Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end

  def private_visibility
    ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS
  end

  def oai_metadata
    @oai_metadata ||= oai_records.map do |record|
      attrs = {}
      # logger.info("Requesting the metadata for #{ark}...")

      metadata = record.at_xpath("xmlns:metadata")
      dublin_core = metadata.at_xpath("oai_dc:dc", "oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/")
      children = dublin_core.xpath("./*")

      children.each do |child|
        key = child.name.to_sym
        value = child.text

        attrs[key] = value
      end

      # Determine the visibility by requesting the Bitstreams without an auth. token
      attrs[:visibility] = if publicly_visible?
                             default_visibility
                           else
                             private_visibility
                           end

      # All items must have a title
      @title = attrs.fetch(:title, nil)
      raise(StandardError, "Failed to find the title element for #{ark}") if @title.nil?

      # Publisher is used to cases where there is one MMS ID for many DSpace Items
      @publisher = attrs.fetch(:publisher, nil)
      @logger.warn("Failed to retrieve the `publisher` field for #{ark}") if @publisher.nil?

      # Ensure that the identifier does not include the full URL
      # identifier = attrs.fetch(:identifier, nil)
      # unless identifier.nil?
      #  ark = identifier.gsub("http://arks.princeton.edu/", "")
      #  attrs["identifier"] = ark
      # end

      attrs["source_metadata_identifier"] = source_metadata_identifier unless source_metadata_identifier.nil?

      logger.info "Successfully retrieved the Bitstreams and metadata for #{@title}."

      attrs
    end
  end

  # Cases where one MMS ID in Orangelight maps to multiple DataSpace Items should not apply remote metadata
  def change_set_param
    if apply_remote_metadata?
      "ScannedResource"
    else
      "DspaceResource"
    end
  end

  def ingest!(**attrs)
    raise(StandardError, "Failed to retrieve bitstreams for #{ark}. Perhaps you require an authentication token?") if bitstreams.empty?

    logger.info "Downloading the Bitstreams for #{ark}..."
    download_bitstreams

    logger.info "Requesting the metadata for #{ark}..."
    oai_metadata.each do |metadata|
      logger.info "Successfully retrieved the Bitstreams and metadata for #{@title}."

      metadata.merge!(attrs)
      identifier = metadata.fetch(:identifier, nil)

      if !identifier.nil?
        persisted = find_resources_by_ark(value: identifier)
        if !persisted.empty?
          logger.warn("Existing #{ark} found for persisted resources: #{persisted.join(',')}")
          next
        end
      end

      IngestFolderJob.perform_later(
        directory: dir_path,
        change_set_param: change_set_param,
        class_name: class_name,
        file_filters: filters,
        **metadata
      )
      logger.info "Enqueued the ingestion of #{@title}."
    end
  end

  def ingest_now!(**attrs)
    raise(StandardError, "Failed to retrieve bitstreams for #{ark}. Perhaps you require an authentication token?") if bitstreams.empty?

    logger.info "Downloading the Bitstreams for #{ark}..."
    download_bitstreams

    logger.info "Requesting the metadata for #{ark}..."
    persisted = []
    oai_metadata.each do |metadata|
      logger.info "Successfully retrieved the Bitstreams and metadata for #{@title}."

      metadata.merge!(attrs)
      identifier = metadata.fetch(:identifier, nil)

      if !identifier.nil?
        persisted = find_resources_by_ark(value: identifier)
        if !persisted.empty?
          logger.warn("Existing #{ark} found for persisted resources: #{persisted.join(',')}")
          next
        end
      end

      resource = IngestFolderJob.perform_now(
        directory: dir_path,
        change_set_param: change_set_param,
        class_name: class_name,
        file_filters: filters,
        **metadata
      )
      persisted << resource
      logger.info "Enqueued the ingestion of #{@title}."
    end

    persisted
  end

  def class_name
    "ScannedResource"
  end

  def filters
    [".pdf", ".jpg", ".png", ".tif", ".TIF", ".tiff", ".TIFF"]
  end

  private

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def find_resources_by_ark(value:)
      query_service.custom_queries.find_many_by_property(property: :identifier, values: [value])
    end

    def download_bitstream(url:, file_path:)
      return if File.exist?(file_path)

      command = "wget -c '#{url}' -O '#{file_path}'"
      _output, status = Open3.capture2e(command)
      raise("Failed to execute #{command}") if status.exitstatus != 0
    end

    def dspace_config
      @dspace_config ||= Figgy.config.fetch("dspace")
    end

    def download_path
      @download_path ||= dspace_config.fetch("download_path")
    end

    def dir_path
      @dir_path ||= File.join(download_path, id.to_s)
    end

    def rest_request(path: "/", params: {}, headers: {})
      conn = Faraday.new(
        url: @rest_base_url,
        headers: headers
      )

      response = conn.get(path, params)

      JSON.parse(response.body)
    end

    def download_bitstreams
      FileUtils.mkdir_p(dir_path)

      bitstreams.each do |bitstream|
        next unless bitstream.key?("name")

        name = bitstream["name"]
        file_path = File.join(dir_path, name)

        next unless bitstream.key?("sequenceId")

        sequence_id = bitstream["sequenceId"]
        url = "#{@download_base_url}/#{sequence_id}"

        download_bitstream(url: url, file_path: file_path)
      end
    end

    def oai_records
      oai_identifier = "oai:dataspace.princeton.edu:#{handle}"
      params = {
        verb: "GetRecord",
        metadataPrefix: "oai_dc",
        identifier: oai_identifier
      }
      headers = {
        "Accept": "application/xml"
      }

      conn = Faraday.new(
        url: @base_url,
        headers: headers
      )
      response = conn.get("/oai/request", params)

      document = Nokogiri::XML.parse(response.body)
      document.xpath("xmlns:OAI-PMH/xmlns:GetRecord/xmlns:record")
    end
end
