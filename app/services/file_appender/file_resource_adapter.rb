# frozen_string_literal: true
class FileAppender
  class FileResourceAdapter
    attr_reader :file_resource
    def initialize(file_resource:)
      @file_resource = file_resource
    end

    def file_metadata
      return file_resource if file_metadata?
      return file_resource.file_metadata if file_set?
      raise NotImplementedError, "Attempted to retrieve the metadata for an unsupported file resource: #{file_resource.class}"
    end

    def file_metadata?
      !file_resource.respond_to?(:file_metadata) && file_resource.respond_to?(:original_filename)
    end

    def file_set?
      file_resource.respond_to?(:file_metadata) && !file_resource.respond_to?(:member_ids)
    end

    def id
      file_resource.id
    rescue
      raise NotImplementedError, "Attempted to retrieve the ID for an unsupported file resource: #{file_resource.class}"
    end
  end
end
