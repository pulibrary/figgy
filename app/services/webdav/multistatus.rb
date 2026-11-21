module Webdav
  # Renders a PROPFIND response (RFC 4918 multistatus). Every entry gets the
  # same standard property set no matter what the client asked for, which all
  # common clients accept. Built as a string because listings can run to tens
  # of thousands of entries.
  class Multistatus
    attr_reader :entries, :root
    # @param entries [Array<(Array<String>, Entry)>] path segments and entry
    def initialize(entries, root:)
      @entries = entries
      @root = root
    end

    def to_xml
      out = +%(<?xml version="1.0" encoding="utf-8"?>\n<D:multistatus xmlns:D="DAV:">)
      entries.each { |segments, entry| out << response_xml(segments, entry) }
      out << "</D:multistatus>\n"
    end

    def self.href(root, segments, collection)
      path = segments.map { |s| ERB::Util.url_encode(s) }.join("/")
      "#{root}/#{path}#{'/' if collection && path.present?}"
    end

    private

      def response_xml(segments, entry)
        props = [
          "<D:displayname>#{esc(entry.name)}</D:displayname>",
          "<D:getlastmodified>#{entry.mtime.httpdate}</D:getlastmodified>",
          "<D:creationdate>#{entry.mtime.utc.iso8601}</D:creationdate>"
        ]
        props += if entry.collection?
                   ["<D:resourcetype><D:collection/></D:resourcetype>"]
        else
                   [
                     "<D:resourcetype/>",
                     # Left out when unknown (IIIF derivatives) - RFC 4918
                     # makes it optional, and a guess would break clients.
                     ("<D:getcontentlength>#{entry.size.to_i}</D:getcontentlength>" if entry.size),
                     "<D:getcontenttype>#{esc(entry.content_type)}</D:getcontenttype>",
                     "<D:getetag>#{esc(entry.etag)}</D:getetag>"
                   ].compact
        end
        "<D:response><D:href>#{esc(self.class.href(root, segments, entry.collection?))}</D:href>" \
          "<D:propstat><D:prop>#{props.join}</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>"
      end

      def esc(str)
        str.to_s.encode(xml: :text)
      end
  end
end
