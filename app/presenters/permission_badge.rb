# frozen_string_literal: true

class PermissionBadge
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper

  # Constructor
  # @param visibility [String] the current visibility
  def initialize(visibility, public_readable_state = nil)
    @visibility = visibility
    @public_readable_state = public_readable_state
  end

  # Draws div tags with bootstrap labels representing the items visibility
  # @return [String] the span markup
  def render
    content_tag(:div, children, class: "label #{label_class}") + computed_visibility_notice
  end

  # Retrieve the text for the badge
  # @return [String] the text for the badge
  # Could return nil
  def text
    visibility_term&.label
  end

  private

    # Get a Term object for the visibility option
    def visibility_term
      @visibility_term ||= ControlledVocabulary.for(:visibility).find(@visibility)
    end

    # Draw a notice representing the computed visibility status
    def computed_visibility_notice
      return if @public_readable_state.nil?
      content_tag(:div, computed_visibility_note, class: "alert alert-inline #{computed_visibility_class}")
    end

    # Generate a note of the final visibility, including both the visibility property and workflow state
    def computed_visibility
      return "suppressed_workflow" unless @public_readable_state
      @visibility
    end

    # Retrieve the text description for the computed visibility
    # @return [String] the html text
    def computed_visibility_note
      I18n.t("computed_visibility.#{computed_visibility}.note_html")
    end

    # Retrieve the class for the badge elements
    # @return [String] the class name
    def computed_visibility_class
      I18n.t("computed_visibility.#{computed_visibility}.class")
    end

    # Retrieve the class for the badge elements
    # @return [String] the class name
    def label_class
      visibility_term&.label_class
    end

    def text_span
      content_tag(:span, text, class: "text")
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
