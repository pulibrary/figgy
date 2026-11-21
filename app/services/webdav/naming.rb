module Webdav
  # Converts titles and filenames into safe, unique, stable path segments, and
  # parses resource IDs back out of them.
  #
  # Resources are named "<title> [<uuid>]" - titles aren't unique, so the ID
  # makes the name unique and lets us resolve a path segment back to a resource
  # with a single primary key lookup, no matter which directory it's listed in.
  module Naming
    UUID = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
    RESOURCE_SEGMENT = /\[(#{UUID})\]\z/
    MAX_TITLE_LENGTH = 120
    MAX_FILENAME_LENGTH = 200

    module_function

    def resource_dir_name(title:, id:, position: nil)
      name = "#{truncate(sanitize(title.presence || 'Untitled'), MAX_TITLE_LENGTH)} [#{id}]"
      position ? "#{position} - #{name}" : name
    end

    def file_name(filename:, position:)
      base = sanitize(filename.presence || "file")
      ext = File.extname(base)
      ext = "" if ext.length > 12
      stem = truncate(base.delete_suffix(ext), MAX_FILENAME_LENGTH - ext.length)
      "#{position} - #{stem}#{ext}"
    end

    # @return [String, nil] the resource ID embedded in a path segment
    def resource_id(segment)
      segment.to_s[RESOURCE_SEGMENT, 1]
    end

    # Zero-padded so that a plain alphabetical sort (which is what every
    # file browser does) preserves the resource's member order.
    def position(index, count)
      (index + 1).to_s.rjust([count.to_s.length, 4].max, "0")
    end

    def sanitize(str)
      str.to_s.unicode_normalize(:nfc).gsub(%r{[/\\\x00-\x1f\x7f]}, "_").squish.sub(/\A\.+/, "")
    end

    def truncate(str, length)
      str.length > length ? "#{str[0, length - 1].rstrip}…" : str
    end
  end
end
