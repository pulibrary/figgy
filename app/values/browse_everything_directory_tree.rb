# frozen_string_literal: true

class BrowseEverythingDirectoryTree
  attr_reader :container_ids
  # @param container_ids [Array<String>]
  def initialize(container_ids)
    @container_ids = container_ids
  end

  def tree
  end

  # {"lapidus" => [{"/lapidus/1234567" => []}]
  def ingest_ids
    container_ids.reject do |path|
      container_ids.any? do |child_path|
        child_path != path && child_path.start_with?(path)
      end
    end
  end
end
