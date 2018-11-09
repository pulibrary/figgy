# frozen_string_literal: true
require "rails_helper"

RSpec.describe DynamicChangeSet do
  let(:change_set_class) { described_class }

  describe "dynamic change_set" do
    context "if change_set is simple" do
      resource = FactoryBot.build(:scanned_resource, change_set: "simple")
      it "returns a SimpleResourceChangeSet" do
        expect(change_set_class.new(resource).class).to eq SimpleResourceChangeSet
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
end
