# frozen_string_literal: true

require "rails_helper"

RSpec.describe TemplateChangeSet do
  subject(:change_set) { described_class.new(template) }
  let(:template) { Template.new(model_class: model_class) }
  let(:model_class) { "EphemeraFolder" }

  describe "#child_change_set" do
    before do
      change_set.prepopulate!
    end
    it "generates a change set based on model_name" do
      expect(change_set.child_change_set.class).to eq EphemeraFolderChangeSet
    end
    it "marks every property as not required for the nested change_set" do
      expect(change_set.child_change_set.required?(:title)).to eq false
    end
    it "can set nested properties" do
      change_set.validate(nested_properties: [{title: "Test"}])
    end
  end

  describe "validations" do
    context "when given a non-UUID for a parent resource" do
      it "is not valid" do
        change_set.validate(parent_id: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a parent resource which does not exist" do
      it "is not valid" do
        change_set.validate(parent_id: ["b8823acb-d42b-4e62-a5c9-de5f94cbd3f6"])
        expect(change_set).not_to be_valid
      end
    end
  end
end
