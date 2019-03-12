# frozen_string_literal: true
# Class modeling configuration options for the Universal Viewer
class ViewerConfiguration < ActiveSupport::HashWithIndifferentAccess
  # Provides the default values for the viewer
  # @return [Hash]
  def self.default_values
    {
      "modules" =>
      {
        "pagingHeaderPanel" =>
        {
          "options" =>
          {
            "autoCompleteBoxEnabled" => false,
            "imageSelectionBoxEnabled" => true
          }
        },
        "contentLeftPanel" =>
        {
          "options" =>
          {
            "branchNodesSelectable" => true,
            "defaultToTreeEnabled" => true
          }
        },
        "footerPanel" =>
        {
          "options" =>
          {
            "shareEnabled" => false
          }
        }
      }
    }
  end

  # Constructor
  # @param values [Hash] configuration options for the Universal Viewer
  # @see https://github.com/UniversalViewer/universalviewer/wiki/Configuration
  def initialize(values = {})
    build_values = self.class.default_values.merge(values)

    super(build_values)
  end
end
