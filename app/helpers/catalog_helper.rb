# frozen_string_literal: true
module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def render_document_heading(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    document ||= @document

    val = presenter(document).heading
    content_tag(tag, val, itemprop: "name", dir: val.to_s.dir)
  end
end
