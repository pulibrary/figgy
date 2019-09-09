# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSet do
  let(:change_set_class) { described_class }

  describe "#for factory" do
    context "if change_set is simple" do
      resource = FactoryBot.build(:scanned_resource, change_set: "simple")
      it "returns a SimpleChangeSet" do
        expect(change_set_class.for(resource).class).to eq SimpleChangeSet
      end
    end
    context "if change_set is recording" do
      resource = FactoryBot.build(:scanned_resource, change_set: "recording")
      it "returns a RecordingChangeSet" do
        expect(change_set_class.for(resource).class).to eq RecordingChangeSet
      end
    end
    context "if change_set is not set, but a param is provided" do
      resource = FactoryBot.build(:scanned_resource)
      it "returns a RecordingChangeSet" do
        expect(change_set_class.for(resource, change_set_param: "recording").class).to eq RecordingChangeSet
      end
    end
    it "returns a ChangeSet class based on the resource" do
      resource = FactoryBot.build(:scanned_resource)
      expect(change_set_class.for(resource).class).to eq ScannedResourceChangeSet
    end
  end

  describe "#class_from_param" do
    context "when given something that can't be constantized" do
      before do
        allow(Valkyrie.logger).to receive(:error)
      end
      it "returns a DynamicChangeSet and logs an error" do
        expect(described_class.class_from_param("bla")).to be nil
        expect(Valkyrie.logger).to have_received(:error).with("Failed to find the ChangeSet class for bla.")
      end
    end
    context "when given something that can be converted" do
      it "returns the change set" do
        expect(described_class.class_from_param("simple")).to eq SimpleChangeSet
      end
    end
  end
end
