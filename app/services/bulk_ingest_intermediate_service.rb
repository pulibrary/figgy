# frozen_string_literal: true
class BulkIngestIntermediateService
  # @param [Symbol] property the metadata property used to link the file to an existing resource
  # @param [Logger] logger for the jobs
  # @param [Boolean] background whether or not the jobs should be performed asynchronously
  def initialize(property:, logger: Valkyrie.logger, background: false)
    @property = property
    @logger = logger
    @background = background
  end

  # Iterate through a directory and parse only child directories which may contain image files
  # @param [String] base_directory file system path for the directory
  def ingest(base_directory)
    Dir["#{base_directory}/*"].sort.each do |entry|
      next unless File.directory?(entry)

      bib_id = File.basename(entry)

      ingest_directory(directory: entry, property_value: bib_id)
    end
  end

  private

    # Retrieves the metadata adapter for persisting and indexing resources
    # @return [IndexingAdapter]
    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    # Retrieves the query service using the metadata adapter
    # @return [QueryService]
    delegate :query_service, to: :metadata_adapter

    # Query for the modified resource
    # @param [String] value the metadata property value used to query for the resource
    # @return [Valkyrie::Resource]
    # @raise [Valkyrie::Persistence::ObjectNotFoundError]
    def find_resource(value)
      results = metadata_adapter.query_service.custom_queries.find_by_property(property: @property, value: value)
      resources = results.to_a
      raise Valkyrie::Persistence::ObjectNotFoundError if resources.empty?
      resources.first
    end

    # Determine whether or not the jobs should be performed asynchronously
    # @return [Boolean]
    def background?
      @background
    end

    # Parse and extract a numeric index from a file path
    # @param [String] tiff_entry the file path
    # @return [String]
    def extract_index(tiff_entry)
      index_m = /\/(\d+)\./.match(tiff_entry)

      unless index_m
        @logger.warn "Failed to parse the index integer from #{tiff_entry}"
        return
      end

      index_value = index_m[1]
      index = index_value.to_i
      index - 1
    end

    # For a given directory, ingest all of the image files and spawn IngestIntermediateFileJobs
    #   (appending these image files to existing resources)
    # @param [String] directory file system path for the directory
    # @param [String] property_value metadata property value linking the files to existing resources
    # @raise [Valkyrie::Persistence::ObjectNotFoundError]
    def ingest_directory(directory:, property_value:)
      tiff_entries = Dir["#{directory}/*tif*"].sort
      return if tiff_entries.empty?

      begin
        resource = find_resource(property_value)
      rescue Valkyrie::Persistence::ObjectNotFoundError => not_found_error
        @logger.error "#{self.class}: Resource not found using property: #{@property}, and value: #{property_value}"
        raise not_found_error
      end

      decorated = resource.decorate

      tiff_entries.each do |tiff_entry|
        tiff_path = File.expand_path(tiff_entry)
        tiff_index = extract_index(tiff_path)
        next if tiff_index.nil?

        file_set = decorated.decorated_file_sets[tiff_index]

        if file_set.nil?
          @logger.warn "Failed to map #{tiff_path} to a FileSet for the Resource #{resource.id}"
          next
        end

        if background?
          IngestIntermediateFileJob.set(queue: :low).perform_later(file_path: tiff_path, file_set_id: file_set.id.to_s)
        else
          IngestIntermediateFileJob.perform_now(file_path: tiff_path, file_set_id: file_set.id.to_s)
        end
      end
    end
end
