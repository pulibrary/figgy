# frozen_string_literal: true
class FileAppender
  class FileResources < Array
    def initialize(*args)
      super(*args)
      @file_resources = {}
    end

    # Retrieve the file metadata for all elements in the set
    def file_metadata
      map { |file_node| file_resource(file_node).file_metadata }
    end

    # Retrieve the ID's for the set
    def ids
      map { |file_node| file_resource(file_node).id }
    end

    private

      def file_resource(file_node)
        @file_resources[file_node] ||= FileResourceAdapter.new(file_resource: file_node)
      end
  end
end
