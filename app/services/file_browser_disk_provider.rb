# frozen_string_literal: true
# Provides the hash serialization of a local mounted disk for the FileBrowser
# used for bulk ingest and the file manager.
class FileBrowserDiskProvider
  attr_reader :root, :base, :entry_type
  # @param root [String] Root file path on the server to return file information
  #   from
  # @param base [String, nil] Relative path from root to return file information
  #   from.
  def initialize(root:, base: nil, entry_type: "default")
    @root = Pathname.new(root)
    @base = base.to_s
    @entry_type = entry_type
  end

  def as_json(*_args)
    files.map(&:as_json)
  end

  private

    def entry_klass
      if entry_type == "selene"
        SeleneEntry
      else
        Entry
      end
    end

    def files
      @files ||= valid_children.sort_by(&:basename).map do |file|
        entry_klass.new(file_path: file, root: root)
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
      entry_type: "default",
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
    "/file_browser/disk/default/#{CGI.escape(relative_path)}.json"
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

class SeleneEntry < Entry
  def selectable?
    SeleneIngestPathService.new(file_path).validate
  end

  def directory_json
    {
      label: basename.to_s,
      path: relative_path,
      loadChildrenPath: load_path,
      entry_type: "selene",
      expanded: false,
      expandable: true,
      selected: false,
      selectable: selectable?,
      loaded: false,
      children: []
    }
  end

  def load_path
    "/file_browser/disk/selene/#{CGI.escape(relative_path)}.json"
  end
end
