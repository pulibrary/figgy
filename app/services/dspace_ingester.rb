# frozen_string_literal: true
class DspaceIngester
  attr_reader :json_path, :logger, :handle, :ark

  DSPACE_PAGE_SIZE = 20

  def initialize(handle:, logger: Rails.logger)
    @handle = handle
    @logger = logger

    @json_path = handle
    @ark = @handle.gsub("ark:/", "")
    @base_url = "https://dataspace.princeton.edu"
    @rest_base_url = "https://dataspace.princeton.edu/rest"
    @download_base_url = "#{@base_url}/bitstream/#{ark}"
  end

  def id
    @id ||= begin
              resource = rest_request(path: "handle/#{ark}")

              return {} unless resource.key?("id")
              resource["id"]
            end
  end

  def bitstreams
    @bitstreams ||= begin
                      data = []

                      loop do
                        path = "items/#{id}/bitstreams"
                        params = {
                          offset: data.length,
                          limit: DSPACE_PAGE_SIZE
                        }
                        new_data = rest_request(path: path, params: params)
                        data.concat(new_data) unless new_data.empty?

                        break if new_data.count < DSPACE_PAGE_SIZE
                      end
                      data
                    end
  end

  def ingest!
    download_bitstreams

    mapping = {}

    oai_records.each do |record|
      attrs = {}

      metadata = record.at_xpath("xmlns:metadata")
      dublin_core = metadata.at_xpath("oai_dc:dc", "oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/")
      children = dublin_core.xpath("./*")

      children.each do |child|
        name = if mapping.key?(child.name)
                 mapping[child.name]
               else
                 child.name
               end

        key = name.to_sym
        value = child.text

        attrs[key] = value
      end

      logger.info "ingesting #{attrs[:title]}"

      IngestDspaceAssetJob.perform_now(
        directory: dir_path,
        class_name: class_name,
        file_filters: filters,
        change_set_param: "Simple",
        **attrs
      )
      logger.info "done ingesting #{attrs[:title]}"
    end
  end

  def class_name
    "ScannedResource"
  end

  def filters
    [".pdf", ".jpg", ".png", ".tif", ".TIF", ".tiff", ".TIFF"]
  end

  private

    def download_bitstream(url:, file_path:)
      return if File.exist?(file_path)

      # stdout_and_stderr_str, status = Open3.capture2e("wget -c '#{url}' -O '#{file_path}'")
      Open3.capture2e("wget -c '#{url}' -O '#{file_path}'")
    end

    def dir_path
      # download_file_path = Rails.configuration.dspace.download_file_path
      download_file_path = Rails.root.join("tmp")
      @dir_path = File.join(download_file_path, id.to_s)
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
        Accept: "application/xml"
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
