# frozen_string_literal: true
# Provides the hash serialization of a local mounted disk for the FileBrowser
# used for bulk ingest and the file manager.
class FileBrowserDiskProvider
  attr_reader :root, :base
  # @param root [String] Root file path on the server to return file information
  #   from
  # @param base [String, nil] Relative path from root to return file information
  #   from.
  def initialize(root:, base: nil)
    @root = Pathname.new(root)
    @base = base.to_s
  end

  def as_json(*_args)
    files.map(&:as_json)
  end

  private

    def files
      @files ||= valid_children.sort_by(&:basename).map do |file|
        Entry.new(file_path: file, root: root)
      end
    end

    def valid_children
      root.join(base).children.select do |child|
        !child.basename.to_s.start_with?(".")
      end
    end
end

class Entry
  attr_reader :file_path, :root
  delegate :basename, to: :file_path
  def initialize(file_path:, root:)
    @file_path = file_path
    @root = root
  end

  def as_json
    if file_path.directory?
      directory_json
    else
      file_json
    end
  end

  def directory_json
    {
      label: basename.to_s,
      path: relative_path,
      loadChildrenPath: load_path,
      expanded: false,
      expandable: true,
      selected: false,
      selectable: selectable?,
      loaded: false,
      children: []
    }
  end

  def file_json
    {
      label: basename.to_s,
      path: valkyrie_id,
      expandable: false,
      selectable: true
    }
  end

  def load_path
    "/file_browser/disk/#{CGI.escape(relative_path)}.json"
  end

  # Might want to extract this to the disk adapter somehow.
  def valkyrie_id
    "disk://#{file_path}"
  end

  def relative_path
    @relative_path ||= file_path.relative_path_from(root).to_s
  end

  # A directory is selectable (valid for bulk ingest) if it contains only
  # directories as children
  def selectable?
    valid_children.any?(&:file?) == false && !valid_children.empty?
  end

  def valid_children
    @valid_children ||=
      file_path.children.select do |child|
        !child.basename.to_s.start_with?(".")
      end
  end
end
