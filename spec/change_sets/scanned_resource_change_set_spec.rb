# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedResourceChangeSet do
  subject(:change_set) { described_class.new(scanned_resource) }
  let(:scanned_resource) { ScannedResource.new }
  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end
    context "when given a bad viewing direction" do
      let(:scanned_resource) { ScannedResource.new(viewing_direction: "backwards-to-forwards") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when given a good viewing direction" do
      let(:scanned_resource) { ScannedResource.new(viewing_direction: "left-to-right") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
    context "when given a bad viewing hint" do
      let(:scanned_resource) { ScannedResource.new(viewing_hint: "bananas") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when given a good viewing direction" do
      let(:scanned_resource) { ScannedResource.new(viewing_hint: "paged") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
  end

  describe "#viewing_hint" do
    it "is singular" do
      scanned_resource.viewing_hint = ["Test"]
      change_set.prepopulate!

      expect(change_set.viewing_hint).to eq "Test"
    end
  end

  describe "#viewing_direction" do
    it "is singular" do
      scanned_resource.viewing_direction = ["Test"]
      change_set.prepopulate!

      expect(change_set.viewing_direction).to eq "Test"
    end
  end
end
