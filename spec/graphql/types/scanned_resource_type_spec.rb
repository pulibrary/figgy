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
    it { is_expected.to have_field(:members) }
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

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{scanned_resource.id}"
    end
  end

  describe "#members" do
    it "returns all members" do
      child_resource = FactoryBot.create_for_repository(:scanned_resource)
      metadata_file_set = FactoryBot.create_for_repository(:geo_metadata_file_set)
      image_file_set = FactoryBot.create_for_repository(:geo_image_file_set)
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [metadata_file_set.id, image_file_set.id, child_resource.id])

      type = described_class.new(scanned_resource, {})

      expect(type.members.map(&:id)).to eq [metadata_file_set.id, image_file_set.id, child_resource.id]
    end
  end
end
