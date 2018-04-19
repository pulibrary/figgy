# frozen_string_literal: true
module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def render_document_heading(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    document ||= @document

    # escape manually to allow <br /> to go through unescaped
    val = Array.wrap(presenter(document).heading).map { |v| h(v) }.join("<br />")
    content_tag(tag, val, { itemprop: "name", dir: val.to_s.dir }, false)
  end
end
