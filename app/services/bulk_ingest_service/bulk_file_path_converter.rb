# frozen_string_literal: true
class BulkIngestService
  # Converts file paths to IngestableFiles to attach to a parent.
  class BulkFilePathConverter
    attr_reader :file_paths, :parent_resource, :preserve_file_names
    def initialize(file_paths:, parent_resource:, preserve_file_names: false)
      @file_paths = file_paths
      @parent_resource = parent_resource
      @preserve_file_names = preserve_file_names
    end

    # @return [Array<IngestableFile>]
    def to_a
      previous = nil
      file_paths.map do |f|
        previous = BulkIngestFile.new(
          file_path: f,
          path_converter: self,
          previous: previous
        )
        previous.to_ingestable_file
      end
    end
  end
end
