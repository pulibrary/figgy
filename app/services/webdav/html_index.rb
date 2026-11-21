module Webdav
  # A plain directory listing for GET requests on a folder, so the same URLs
  # can be browsed in a web browser.
  class HtmlIndex
    attr_reader :segments, :entries, :root
    def initialize(segments, entries, root:)
      @segments = segments
      @entries = entries
      @root = root
    end

    def to_html
      title = ERB::Util.h("Figgy /#{segments.join('/')}")
      items = []
      items << link("../", "..") if segments.present?
      entries.each do |entry|
        label = if entry.collection?
                  "#{entry.name}/"
        elsif entry.size
                  "#{entry.name} (#{ActiveSupport::NumberHelper.number_to_human_size(entry.size)})"
        else
                  entry.name
        end
        items << link(Multistatus.href(root, segments + [entry.name], entry.collection?), label)
      end
      <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
        <!doctype html>
        <html><head><meta charset="utf-8"><title>#{title}</title></head>
        <body><h1>#{title}</h1><ul>#{items.join}</ul></body></html>
      HTML
    end

    private

      def link(href, label)
        %(<li><a href="#{ERB::Util.h(href)}">#{ERB::Util.h(label)}</a></li>)
      end
  end
end
