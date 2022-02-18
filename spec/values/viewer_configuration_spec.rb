# frozen_string_literal: true

require "rails_helper"

describe ViewerConfiguration do
  subject(:viewer_configuration) { described_class.new(foo: "bar") }

  describe ".default_values" do
    it "generates the default configuration options" do
      expect(described_class.default_values).to include "modules"
      expect(described_class.default_values["modules"]).to include "pagingHeaderPanel"
      expect(described_class.default_values["modules"]).to include "contentLeftPanel"
      expect(described_class.default_values["modules"]).to include "footerPanel"
      expect(described_class.default_values["modules"]["pagingHeaderPanel"]).to include "options"
      expect(described_class.default_values["modules"]["pagingHeaderPanel"]["options"]).to include(
        "autoCompleteBoxEnabled" => false,
        "imageSelectionBoxEnabled" => true
      )
      expect(described_class.default_values["modules"]["contentLeftPanel"]).to include "options"
      expect(described_class.default_values["modules"]["contentLeftPanel"]["options"]).to include(
        "branchNodesSelectable" => true,
        "defaultToTreeEnabled" => true
      )
      expect(described_class.default_values["modules"]["footerPanel"]).to include "options"
      expect(described_class.default_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => true
      )
      expect(described_class.default_values["modules"]["avCenterPanel"]["options"]).to include(
        "posterImageExpanded" => true
      )
    end
  end

  describe ".new" do
    it "constructs an object with custom properties" do
      expect(viewer_configuration).to include "foo"
      expect(viewer_configuration["foo"]).to eq "bar"
    end
  end

  describe ".disable_share!" do
    it "disables the share value" do
      config = described_class.new
      config.disable_share!
      expect(config.as_json["modules"]["footerPanel"]["options"]["shareEnabled"]).to eq false
    end
  end
end
