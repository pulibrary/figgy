# frozen_string_literal: true
class BrowseEverythingIngestJob < ApplicationJob
  def perform(resource_id, controller_scope_string, selected_files)
    controller_scope = controller_scope_string.constantize
    change_set_persister = controller_scope.change_set_persister
    change_set_class = controller_scope.change_set_class
    resource = change_set_persister.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(resource_id))

    change_set = change_set_class.new(resource)
    selected_files = selected_files.values.map do |x|
      BrowseEverythingFile.new(x.symbolize_keys)
    end
    change_set.validate(files: selected_files)
    change_set_persister.save(change_set: change_set)
  end

  class BrowseEverythingFile
    def initialize(file_name:, file_size:, url:)
      @file_name = file_name
      @file_size = file_size
      @url = url
    end

    def original_filename
      @file_name
    end

    def content_type
      'text/plain'
    end

    def path
      copied_file_name
    end

    def copied_file_name
      return @copied_file_name if @copied_file_name
      BrowseEverything::Retriever.new.download("file_name" => @file_name, "file_size" => @file_size, "url" => @url) do |filename, _retrieved, _total|
        @copied_file_name = filename
      end
      @copied_file_name
    end
  end
end
