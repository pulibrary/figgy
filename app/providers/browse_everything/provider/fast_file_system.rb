# frozen_string_literal: true

module BrowseEverything
  # Override FileSystem provider to not pull down a file handle for every found
  # bytestream. Significantly increases speed, and the file size and mtime
  # aren't useful for us.
  class Provider::FastFileSystem < BrowseEverything::Provider::FileSystem
    def name
      "File System"
    end

    def find_bytestream(id:)
      return unless File.exist?(id)

      bytestream = build_bytestream(id)
      @resources = [bytestream]
      bytestream
    end

    def build_bytestream(file_path)
      absolute_path = File.absolute_path(file_path)
      uri = "file://#{absolute_path}"
      name = File.basename(absolute_path)
      extname = File.extname(absolute_path)
      mime_type = Mime::Type.lookup_by_extension(extname)

      BrowseEverything::Bytestream.new(
        id: absolute_path,
        location: uri,
        name: name,
        size: 0,
        mtime: 0,
        media_type: mime_type,
        uri: uri
      )
    end

    def find_bytestream_children(directory)
      parent_path = Pathname.new(directory.path)
      children = Dir.children(directory.path)
      file_children_paths = children.select do |child|
        File.file?(parent_path.join(child))
      end

      file_children_paths.map do |path|
        build_bytestream(parent_path.join(path))
      end
    end

    def traverse_directory(directory)
      @resources = []
      @resources = find_container_children(directory)
      @resources += find_bytestream_children(directory)
      @resources.sort_by!(&:id)
    end
  end
end
