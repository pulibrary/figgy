# frozen_string_literal: true

# Class modeling configuration options for the Universal Viewer used in digital
# exhibits
class ExhibitViewerConfiguration < ViewerConfiguration
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
        }
      }
    }
  end
end
