# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::ProxyFileSetType do
  subject(:type) { make_graphql_object(described_class, proxy_file_set) }
  let(:proxy_file_set) do
    FactoryBot.create_for_repository(
      :proxy_file_set,
      label: ["File Set Label"]
    )
  end

  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:label).of_type(String) }
  end

  describe "#thumbnail" do
    it "always returns something with blank properties" do
      thumbnail = type.thumbnail
      expect(thumbnail[:thumbnail_url]).to eq ""
      expect(thumbnail[:iiif_service_url]).to eq ""
    end
  end

  describe "#label" do
    it "maps to a resource's first title" do
      expect(type.label).to eq "File Set Label"
    end
  end

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{proxy_file_set.id}"
    end
  end

  describe "#source_metadata_identifier" do
    it "is always nil" do
      expect(type.source_metadata_identifier).to eq nil
    end
  end

  describe "#members" do
    it "returns an empty array" do
      expect(type.members).to eq []
    end
  end

  describe "#viewing_hint" do
    it "returns nil" do
      expect(type.viewing_hint).to eq nil
    end
  end
end
