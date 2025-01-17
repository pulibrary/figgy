# frozen_string_literal: true
class DspaceIngester
  attr_reader :json_path, :logger, :handle
  def initialize(handle:, logger: Rails.logger)
    @handle = handle
    @logger = logger

    @json_path = handle
  end

  def ingest!
    base_url = "https://dataspace.princeton.edu"
    oai_identifier = "oai:dataspace.princeton.edu:#{handle}"
    params = {
      verb: "GetRecord",
      metadataPrefix: "oai_dc",
      identifier: oai_identifier,
    }
    headers = {
      Accept: "application/xml"
    }

    conn = Faraday.new(
      url: base_url,
      headers: headers
    )
    response = conn.get("/oai/request", params)

    document = Nokogiri::XML.parse(response.body)
    get_record = document.root.children.last

    data[:assets].each do |attrs|
      dir = attrs.delete(:path)
      logger.info "ingesting #{attrs[:title]}"

      IngestDSpaceAssetJob.perform_now(
        directory: dir,
        class_name: class_name,
        file_filters: filters,
        change_set_param: "Simple",
        **attrs
      )
      logger.info "done ingesting #{attrs[:title]}"
    end
  end

  def data
    @params ||= JSON.parse(File.read(json_path), symbolize_names: true)
  end

  def class_name
    "ScannedResource"
  end

  def filters
    [".pdf", ".jpg", ".png", ".tif", ".TIF", ".tiff", ".TIFF"]
  end
end
