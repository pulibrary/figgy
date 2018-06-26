# frozen_string_literal: true
require "rails_helper"

describe BoundingBoxHelper do
  let(:property) { :coverage }
  let(:change_set) { ScannedMapChangeSet.new(ScannedMap.new) }

  describe "#bbox_input" do
    it "builds bounding box selector" do
      expect(helper.bbox_input(property, change_set)).to include("data-input-id='scanned_map_coverage'")
    end
  end

  describe "#bbox_display_inputs" do
    subject { helper.bbox_display_inputs }
    it { is_expected.to include("North", "East", "South", "West") }
  end
end
