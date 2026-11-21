module Webdav
  # A single item in a WebDAV listing - either a directory ("collection" in
  # WebDAV parlance) or a file. `segments` is the path from the DAV root.
  #
  # Entries are plain value objects so that resource listings can be cached in
  # memcached.
  Entry = Struct.new(
    :name, :collection, :size, :mtime, :content_type,
    # File entries only. Originals have a file_id; IIIF derivatives have a
    # derivative_url instead (cached originals carry both).
    :file_set_id, :file_id, :derivative_url,
    # Child work directories inside a resource listing only
    :resource_id,
    keyword_init: true
  ) do
    def collection?
      collection ? true : false
    end

    def etag
      %("#{[file_id || derivative_url || name, mtime.to_i, size].join('-')}")
    end
  end
end
