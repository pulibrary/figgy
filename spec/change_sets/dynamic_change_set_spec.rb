# frozen_string_literal: true
require "rails_helper"

RSpec.describe DynamicChangeSet do
  let(:change_set_class) { described_class }

  describe "dynamic change_set" do
    context "if change_set is simple" do
      resource = FactoryBot.build(:scanned_resource, change_set: "simple")
      it "returns a SimpleChangeSet" do
        expect(change_set_class.new(resource).class).to eq SimpleChangeSet
      end
    end
    context "if change_set is recording" do
      resource = FactoryBot.build(:scanned_resource, change_set: "recording")
      it "returns a RecordingChangeSet" do
        expect(change_set_class.new(resource).class).to eq RecordingChangeSet
      end
    end
    it "returns a ChangeSet class based on the resource" do
      resource = FactoryBot.build(:scanned_resource)
      expect(change_set_class.new(resource).class).to eq ScannedResourceChangeSet
    end
  end

  describe "#class_from_param" do
    context "when given something that can't be constantized" do
      it "raises a NameError" do
        expect { described_class.class_from_param("bla") }.to raise_error NameError
      end
    end
    context "when given something that can be converted" do
      it "returns the change set" do
        expect(described_class.class_from_param("simple")).to eq SimpleChangeSet
      end
    end
  end
end
