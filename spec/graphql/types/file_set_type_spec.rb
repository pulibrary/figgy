# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::FileSetType do
  subject(:type) { described_class.new(resource, {}) }
  let(:resource) { FactoryBot.create_for_repository(:file_set, viewing_hint: "individuals", title: ["I'm a label."]) }
  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:viewingHint).of_type(String) }
    it { is_expected.to have_field(:label).of_type(String) }
  end

  describe "#viewing_hint" do
    it "returns a singular value" do
      expect(type.viewing_hint).to eq "individuals"
    end
  end

  describe "#label" do
    it "maps to a resource's first title" do
      expect(type.label).to eq "I'm a label."
    end
  end

  describe "#members" do
    it "returns an empty array" do
      expect(type.members).to eq []
    end
  end
end
