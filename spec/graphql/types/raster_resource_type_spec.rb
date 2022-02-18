# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::RasterResourceType do
  subject(:type) { described_class.new(raster_resource, {}) }
  let(:bibid) { "123456" }
  let(:raster_resource) do
    FactoryBot.create_for_repository(
      :raster_resource,
      title: ["I'm a little teapot", "short and stout"],
      source_metadata_identifier: [bibid],
      thumbnail_id: file_set.id
    )
  end
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }

  before do
    stub_bibdata(bib_id: bibid)
  end

  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:label).of_type(String) }
    it { is_expected.to have_field(:members) }
    it { is_expected.to have_field(:ocrContent) }
    it { is_expected.to have_field(:thumbnail) }
    it { is_expected.to have_field(:sourceMetadataIdentifier).of_type(String) }
  end

  describe "#thumbnail" do
    it "returns nil" do
      expect(type.thumbnail).to be_nil
    end
  end

  describe "#label" do
    it "maps to a resource's first title" do
      expect(type.label).to eq "I'm a little teapot"
    end
  end

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{raster_resource.id}"
    end
  end

  describe "#source_metadata_identifier" do
    it "returns the bib. ID" do
      expect(type.source_metadata_identifier).to eq bibid
    end
  end

  describe "#members" do
    it "returns all members" do
      child_resource = FactoryBot.create_for_repository(:raster_resource)
      metadata_file_set = FactoryBot.create_for_repository(:geo_metadata_file_set)
      raster_file_set = FactoryBot.create_for_repository(:geo_raster_file_set)
      raster_resource = FactoryBot.create_for_repository(:raster_resource, member_ids: [metadata_file_set.id, raster_file_set.id, child_resource.id])

      type = described_class.new(raster_resource, {})

      expect(type.members.map(&:id)).to eq [metadata_file_set.id, raster_file_set.id, child_resource.id]
    end
  end

  describe "#ocr_content" do
    it "returns an empty array" do
      expect(type.ocr_content).to eq []
    end
  end
end
