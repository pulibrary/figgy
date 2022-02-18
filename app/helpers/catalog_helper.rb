# frozen_string_literal: true

module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  # Convert boolean values to Yes/No
  def display_boolean(value)
    value == "true" ? "Yes" : "No"
  end

  # Generates the markup for search result items
  # @param args [Array<Object>]
  # @return [String] the markup
  def render_document_heading(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    document ||= @document

    # escape manually to allow <br /> to go through unescaped
    val = Array.wrap(presenter(document).heading).map { |v| h(v) }.join("<br />")
    content_tag(tag, val, {itemprop: "name", dir: val.to_s.dir}, false)
  end

  # Generates the text for faceted search parameters
  # @see Blacklight::CatalogHelperBehavior#render_search_to_page_title_filter
  #
  # @param facet [String] the facet parameter name
  # @param values [Array<String>] the facet parameter values
  # @return [String]
  def render_search_to_page_title_filter(facet, values)
    return "" unless facet && values
    super(facet, values)
  end

  def render_visibility_label(value)
    PermissionBadge.new(value).text.titleize
  rescue NoMethodError
    Honeybadger.notify("Bad visibility value: #{value}")
    value
  end
end
