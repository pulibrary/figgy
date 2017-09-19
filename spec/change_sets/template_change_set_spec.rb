# frozen_string_literal: true
require 'rails_helper'

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
      change_set.validate(nested_properties: [{ title: "Test" }])
    end
  end
end
