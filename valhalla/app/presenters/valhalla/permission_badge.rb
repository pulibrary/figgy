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
      content_tag(:span, children, class: "label #{dom_label_class}")
    end

    private

      # Retrieve the class for the badge elements
      # @return [String] the class name
      def dom_label_class
        I18n.t("valhalla.visibility.#{@visibility}.class")
      end

      # Retrieve the text for the badge
      # @return [String] the text for the badge
      def text
        I18n.t("valhalla.visibility.#{@visibility}.text")
      end

      # Generate the path for the visibility icon
      # @return [String] the path to the visibility icon
      def icon_file_name
        "#{@visibility}_visibility.png"
      end

      # Generate the markup for the visibility icon
      # @return [String] the markup
      def icon
        image_tag("/assets/valhalla/#{icon_file_name}", alt: @visibility, class: "label-icon")
      end

      # Generate the markup within the <span>
      # @return [String] the markup
      def children
        icon + text
      end
  end
end
