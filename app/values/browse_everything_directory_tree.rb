# frozen_string_literal: true

class BrowseEverythingDirectoryTree
  attr_reader :container_ids, :tree
  # @param container_ids [Array<String>]
  def initialize(container_ids)
    @container_ids = container_ids.sort.map { |str| Pathname.new(str) }
  end

  def tree
    @tree ||= parse_container_ids
  end

  def parse_container_ids
    container_ids.each_with_object({}) do |path, h|
      if h[path.dirname.to_s]
        h[path.dirname.to_s] << { path.to_s => [] }
      else
        h[path.to_s] = []
      end
    end
  end

  # {"lapidus" => [{"/lapidus/1234567" => []}]
  def ingest_ids
    tree.map do |parent, children|
      if children.empty?
        parent
      else
        children.flat_map(&:keys)
      end
    end.flatten
  end
end
