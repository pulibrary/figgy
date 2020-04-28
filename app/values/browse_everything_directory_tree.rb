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

  def child_lookup
    @child_lookup ||=
      begin
        {}.tap do |hsh|
          container_ids.each do |container_id|
            hsh[container_id] = container_ids.select { |x| x.dirname == container_id }
          end
        end
      end
  end

  def parse_container_ids
    child_lookup.each_with_object({}) do |path_arr, hsh|
      path, children = path_arr
      # For every root directory, populate the hash with built hashes of its
      # children.
      unless child_lookup.key?(path.dirname)
        hsh[path.to_s] = build_objects(child_lookup, children)
      end
    end
  end

  def build_objects(child_lookup, children)
    # If the children have a key in the child lookup, it has children, so
    # recurse. Otherwise just return an empty hash per child.
    children.each_with_object({}) do |child, hsh|
      hsh[child.to_s] = if child_lookup[child]
                          build_objects(child_lookup, child_lookup[child])
                        else
                          {}
                        end
    end
  end

  # {"lapidus" => [{"/lapidus/1234567" => []}]
  def ingest_ids
    tree.flat_map do |parent, children|
      if children.empty?
        parent
      else
        children.map(&:first)
      end
    end
  end
end
