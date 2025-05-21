# frozen_string_literal: true
class DspaceIngester
  attr_reader :json_path, :logger, :handle, :ark, :resource_types
  attr_writer :id

  class DspaceIngestionError < StandardError; end

  def self.default_page_size
    20
  end

  def self.default_logger
    Rails.logger
  end

  def self.default_resource_types
    [
      "item"
    ]
  end

  def ark_url
    "http://arks.princeton.edu/ark:/#{ark}"
  end

  def initialize(handle:, delete_preexisting: false, dspace_api_token: nil, **_attrs)
    @handle = handle

    # Optional arguments
    @delete_preexisting = delete_preexisting
    @dspace_api_token = dspace_api_token

    @logger = self.class.default_logger
    @resource_types = self.class.default_resource_types
    @page_size = self.class.default_page_size

    @json_path = handle
    @ark = @handle.gsub("ark:/", "")
    @base_url = "https://dataspace.princeton.edu/"
    @rest_base_url = URI.parse(@base_url + "rest/")

    @title = nil
    @publisher = nil
  end

  def ingest_resource(**job_args)
    IngestFolderJob.perform_now(**job_args)

    results = find_resources_by_ark(value: ark_url)
    raise(DspaceIngestionError, "Failed to persist the resource with #{ark_url}") if results.empty?

    results.last
  end

  def ingest!(parent_id: nil, **attrs)
    raise(DspaceIngestionError, "Failed to retrieve bitstreams for #{ark}. Perhaps you require an authentication token?") if bitstreams.empty?

    logger.info "Downloading the Bitstreams for #{ark}..."
    download_bitstreams

    logger.info "Requesting the metadata for #{ark}..."

    oai_metadata.each do |metadata|
      logger.info "Successfully retrieved the Bitstreams and metadata for #{@title}."

      metadata.merge!(attrs)
      # This is the ARK as a URL
      identifier = metadata.fetch(:identifier, nil)

      raise(DspaceIngestionError, "Failed to find the identifier for #{ark}") if identifier.blank?
      persisted = find_resources_by_ark(value: identifier)

      unless persisted.empty?
        if @delete_preexisting
          persisted.each do |resource|
            change_set = ChangeSet.for(resource)
            change_set_persister.buffer_into_index do |persist|
              persist.delete(change_set: change_set)
            end
          end
        end
      end

      ingested_resource = ingest_resource(
        directory: dir_path,
        change_set_param: change_set_param,
        class_name: class_name,
        file_filters: filters,
        **metadata
      )

      unless parent_id.nil?
        AddMemberJob.perform_later(resource_id: ingested_resource.id.to_s, parent_id: parent_id.to_s)
      end

      logger.info("Persisted the resource #{ingested_resource}.")
    end
  end

  private

    def request_resource(path:, params: {}, headers: {})
      uri = URI.parse(@rest_base_url.to_s + path)
      @logger.info("Requesting #{uri} #{params} #{headers}")

      response = Faraday.get(uri, params, headers)
      raise("Failed to request bibliographic metadata: #{uri} #{params} #{headers}") if response.status == 404

      JSON.parse(response.body)
    end

    def paginated_request(path:, headers: {}, offset: 0, **params)
      default_params = {
        offset: offset,
        limit: @page_size
      }
      request_params = default_params.merge(params)

      request_resource(path: path, params: request_params, headers: headers)
    end

    def request_headers(**options)
      headers = options
      headers["rest-dspace-token"] = @dspace_api_token unless @dspace_api_token.nil?

      headers
    end

    def rest_resource
      @rest_resource ||= begin
                path = "handle/#{ark}"
                headers = request_headers("Accept" => "application/json")
                resource = request_resource(path: path, headers: headers)

                remote_type = resource["type"]
                raise(DspaceIngestionError, "Handle resolves to resource type #{remote_type}, expected #{resource_types}") unless resource_types.include?(remote_type)

                resource
              end
    end

    def id
      @id ||= begin
                return unless rest_resource.key?("id")
                rest_resource["id"]
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

                          break if new_data.count < @page_size
                        end
                        data
                      end
    end

    def publicly_visible?
      @publicly_visible ||= begin
                              public_bitstreams = request_bitstreams(headers: {}, offset: 0, limit: 1)
                              !public_bitstreams.empty?
                            end
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
        raise(DspaceIngestionError, "Failed to find the title element for #{ark}") if @title.nil?

        # Publisher is used to cases where there is one MMS ID for many DSpace Items
        @publisher = attrs.fetch(:publisher, nil)
        @logger.warn("Failed to retrieve the `publisher` field for #{ark}") if @publisher.nil?

        logger.info "Successfully retrieved the Bitstreams and metadata for #{@title}."

        attrs[:source_metadata_identifier] = nil

        attrs
      end
    end

    def resource_klass
      ScannedResource
    end

    def new_resource
      resource_klass.new
    end

    def resource_change_set
      @resource_change_set ||= ChangeSet.for(new_resource)
    end

    def class_name
      resource_klass.name
    end

    def change_set_param
      class_name
    end

    def filters
      [".pdf", ".jpg", ".png", ".tif", ".TIF", ".tiff", ".TIFF"]
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def find_resources_by_ark(value:)
      query_service.custom_queries.find_many_by_property(property: :identifier, values: [value])
    end

    def change_set_persister
      ChangeSetPersister.default
    end

    def download_bitstream(url:, file_path:)
      File.delete(file_path) if File.exist?(file_path)

      command = "/usr/bin/env curl -H 'rest-dspace-token: #{@dspace_api_token}' -o '#{file_path}' '#{url}'"

      output, status = Open3.capture2e(command)

      raise("Failed to execute #{command}: #{output}") if status.exitstatus != 0
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

    def download_bitstreams
      FileUtils.mkdir_p(dir_path)

      bitstreams.each do |bitstream|
        name = bitstream["name"]
        file_path = File.join(dir_path, name)

        bitstream_id = bitstream["id"]

        url = "#{@rest_base_url}bitstreams/#{bitstream_id}/retrieve"

        download_bitstream(url: url, file_path: file_path)
      end
    end

    def oai_document
      @oai_document ||= begin
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

                          Nokogiri::XML.parse(response.body)
                        end
    end

    def oai_record_xpath
      "//xmlns:OAI-PMH/xmlns:GetRecord/xmlns:record"
    end

    def oai_records
      @oai_records ||= oai_document.xpath(oai_record_xpath)
    end
end
