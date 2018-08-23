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

  # Determine whether or not the jobs should be performed asynchronously
  # @return [Boolean]
  def background?
    @background
  end

  # For a given directory, ingest all of the image files and spawn IngestIntermediateFileJobs
  #   (appending these image files to existing resources)
  # @param [String] directory file system path for the directory
  # @param [String] property_value metadata property value linking the files to existing resources
  def ingest_directory(directory:, property_value:)
    Dir["#{directory}/*tif?"].sort.each do |tiff_entry|
      tiff_path = File.expand_path(tiff_entry)

      if background?
        IngestIntermediateFileJob.set(queue: :low).perform_later(tiff_path, property: @property, value: property_value)
      else
        IngestIntermediateFileJob.perform_now(tiff_path, property: @property, value: property_value)
      end
    end
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
end
