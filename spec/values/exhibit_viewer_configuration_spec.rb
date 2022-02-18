# frozen_string_literal: true

require "rails_helper"

describe ExhibitViewerConfiguration do
  subject(:viewer_configuration) { described_class.new(foo: "bar") }

  describe ".default_values" do
    it "generates the default configuration options" do
      expect(described_class.default_values).to include "modules"
      expect(described_class.default_values["modules"]).to include "pagingHeaderPanel"
      expect(described_class.default_values["modules"]["pagingHeaderPanel"]).to include "options"
      expect(described_class.default_values["modules"]["pagingHeaderPanel"]["options"]).to include(
        "autoCompleteBoxEnabled" => false,
        "imageSelectionBoxEnabled" => true
      )
    end
  end

  describe ".new" do
    it "constructs an object with custom properties" do
      expect(viewer_configuration).to include "foo"
      expect(viewer_configuration["foo"]).to eq "bar"
    end
  end
end
