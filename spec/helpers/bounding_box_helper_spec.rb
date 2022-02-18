# frozen_string_literal: true

require "rails_helper"

describe BoundingBoxHelper do
  let(:property) { :coverage }
  let(:coverage) { ["northlimit=37.894363; eastlimit=-121.988754; southlimit=37.622934; westlimit=-122.481766; units=degrees; projection=EPSG:4326"] }
  let(:change_set) { ScannedMapChangeSet.new(ScannedMap.new(coverage: coverage)) }

  describe "#bbox_input" do
    it "builds bounding box selector" do
      expect(helper.bbox_input(property, change_set)).to include("data-input-id='scanned_map_coverage'")
      expect(helper.bbox_input(property, change_set)).to include("data-coverage='#{coverage}'")
    end
  end

  describe "#bbox_display_inputs" do
    subject { helper.bbox_display_inputs }
    it { is_expected.to include("North", "East", "South", "West") }
  end
end
