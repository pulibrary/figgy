# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::ScannedResourceType do
  subject(:type) { described_class.new(scanned_resource, {}) }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "individuals", title: ["I'm a little teapot", "short and stout"]) }
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
      expect(type.label).to eq "I'm a little teapot"
    end
  end
end
