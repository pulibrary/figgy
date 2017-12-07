# frozen_string_literal: true
class FileAppender
  class FileResourceAdapter
    def initialize(file_resource:)
      @file_resource = file_resource
    end

    def file_metadata
      return @file_resource if ResourceDetector.file_metadata?(@file_resource)
      return @file_resource.file_metadata if ResourceDetector.file_set?(@file_resource)
      raise NotImplementedError, "Attempted to retrieve the metadata for an unsupported file resource: #{@file_resource.class}"
    end

    def id
      @file_resource.id
    rescue
      raise NotImplementedError, "Attempted to retrieve the ID for an unsupported file resource: #{@file_resource.class}"
    end
  end
end
