# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:scanned_resource) { ScannedResource.new(title: 'Test', rights_statement: 'Stuff', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE) }
  let(:form_resource) { scanned_resource }
  before do
    stub_bibdata(bib_id: '123456')
  end
  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end
    context "when given a bad viewing direction" do
      let(:form_resource) { scanned_resource.new(viewing_direction: "backwards-to-forwards") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when given a good viewing direction" do
      let(:form_resource) { scanned_resource.new(viewing_direction: "left-to-right") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
    context "when given a bad viewing hint" do
      let(:form_resource) { scanned_resource.new(viewing_hint: "bananas") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when given a good viewing direction" do
      let(:form_resource) { scanned_resource.new(viewing_hint: "paged") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
    context "when neither title or metadata identifier is set" do
      let(:form_resource) { scanned_resource.new(title: "", source_metadata_identifier: "") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when title is an empty array" do
      it "is invalid" do
        expect(change_set.validate(title: [""])).to eq false
      end
    end
    context "when only metadata_identifier is set" do
      let(:form_resource) { scanned_resource.new(title: "", source_metadata_identifier: "123456") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
    context "when rights_statement isn't set" do
      let(:form_resource) { scanned_resource.new(rights_statement: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when visibility isn't set" do
      let(:form_resource) { scanned_resource.new(visibility: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
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
