# frozen_string_literal: true
# Provides the hash serialization of a local mounted disk for the FileBrowser
# used for bulk ingest and the file manager.
class FileBrowserDiskProvider
  attr_reader :root, :base
  def initialize(root:, base: nil)
    @root = Pathname.new(root)
    @base = base.to_s
  end

  def as_json(*_args)
    files.map(&:as_json)
  end

  private

    def files
      @files ||= root.join(base).children.sort_by(&:basename).map do |file|
        Entry.new(file_path: file, root: root)
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
    else
      {
        label: basename.to_s,
        path: valkyrie_id,
        expandable: false,
        selectable: true
      }
    end
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
    file_path.children.any?(&:file?) == false
  end
end
