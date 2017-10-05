# frozen_string_literal: true
class BulkIngestService
  attr_reader :change_set_persister, :logger
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  def initialize(change_set_persister:, logger: Valkyrie.logger)
    @logger = logger
    @change_set_persister = change_set_persister
  end

  def attach_each_dir(base_directory:, property:, file_filter: nil)
    Dir["#{base_directory}/*"].sort.each do |subdir|
      next unless File.directory?(subdir)
      logger.info "Attaching #{subdir}"
      attach_dir(base_directory: subdir, property: property, file_filter: file_filter)
    end
  end

  def attach_dir(base_directory:, property:, file_filter: nil)
    property_value = File.basename(base_directory)
    resource = property_query_service.find_by_string_property(property: property, value: property_value).first

    logger.info "Found #{resource.id} for #{property}:#{property_value}"
    attach_files(base_directory: base_directory, resource: resource, file_filter: file_filter)
  end

  def attach_files(base_directory:, resource:, file_filter: nil)
    change_set = DynamicChangeSet.new(resource)
    files = files(base_directory: base_directory, file_filter: file_filter)
    change_set.validate(files: files)
    change_set.sync
    change_set_persister.save(change_set: change_set)
  end

  def files(base_directory:, file_filter: nil)
    files = []
    Dir["#{base_directory}/*"].sort.each do |f|
      next if File.directory?(f)
      next unless file_filter.nil? || f.ends_with?(file_filter)
      files << IngestableFile.new(
        file_path: f,
        mime_type: "image/tiff",
        original_filename: File.basename(f),
        copyable: true
      )
    end
    files
  end

  def property_query_service
    @query_service ||= FindByStringProperty.new(query_service: query_service)
  end
end
