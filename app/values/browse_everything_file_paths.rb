# frozen_string_literal: true
class BrowseEverythingFilePaths
  # Constructor
  # @param selected_files [Hash] hash of files selected in BrowseEverything
  def initialize(selected_files)
    @selected_files = selected_files
  end

  # Finds the lowest common ancestor (parent path)
  # for an array of Pathname objects.
  # @return [Pathname]
  def parent_path
    @parent_path ||= begin
      out_path = file_paths.pop
      file_paths.each do |f|
        out_path = compare_paths(f, out_path)
      end

      out_path
    end
  end

  # Tests if the parent directory directly contains all the selected files.
  # @return [Boolean]
  def parent_path_contains_all_files?
    file_paths.each do |path|
      return false unless path.dirname == parent_path
    end

    true
  end

  private

    # Compares two paths by iterating over their component
    # elements, and returning the last shared element.
    # @param path1 [Pathname]
    # @param path2 [Pathname]
    # @return [Pathname]
    def compare_paths(path1, path2)
      enum1 = path1.descend
      enum2 = path2.descend
      out_path = "/"

      loop do
        begin
          val1 = enum1.next
          val2 = enum2.next
          return out_path unless val1 == val2
          out_path = val1
        rescue StopIteration
          return out_path
        end
      end
    end

    # Builds an array of Pathname objects from a BrowseEverything file hash.
    # @return Array<Pathname>
    def file_paths
      @file_paths ||= begin
        paths = @selected_files.values.map { |x| x["url"].gsub("file://", "") }
        paths.map { |x| Pathname.new(x) }
      end
    end
end
