# frozen_string_literal: true
module Valhalla
  class PermissionBadge
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::AssetTagHelper

    # Constructor
    # @param visibility [String] the current visibility
    def initialize(visibility)
      @visibility = visibility
    end

    # Draws a span tag with styles for a bootstrap label
    # @return [String] the span markup
    def render
      content_tag(:div, children, class: "label #{label_class}")
    end

    private

      # Retrieve the class for the badge elements
      # @return [String] the class name
      def label_class
        I18n.t("valhalla.visibility.#{@visibility}.class")
      end

      # Retrieve the text for the badge
      # @return [String] the text for the badge
      def text
        I18n.t("valhalla.visibility.#{@visibility}.text")
      end

      def text_span
        content_tag(:span, text, class: "text")
      end

      # Generate the path for the visibility icon
      # @return [String] the path to the visibility icon
      def icon_file_name
        "#{@visibility}_visibility"
      end

      # Generate the markup for the visibility icon
      # @return [String] the markup
      def icon
        content_tag(:span, "", class: "icon")
      end

      # Generate the markup within the <span>
      # @return [String] the markup
      def children
        icon + text_span
      end
  end
end
