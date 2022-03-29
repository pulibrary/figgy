# frozen_string_literal: true
class JsonIngester
  attr_reader :json_path, :logger
  def initialize(json_path:, logger: Rails.logger)
    @json_path = json_path
    @logger = logger
  end

  def ingest!
    logger.info "ingesting #{data[:records].length} records"
    data[:records].each do |attrs|
      dir = attrs.delete(:path)
      logger.info "ingesting #{attrs[:title]}"
      IngestFolderJob.perform_now(
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
