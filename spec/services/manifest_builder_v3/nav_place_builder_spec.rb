# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManifestBuilderV3::NavPlaceBuilder do
  describe "#apply" do
    let(:root_node) { ManifestBuilder::RootNode.new(resource) }
    let(:builder) { described_class.new(root_node) }
    let(:manifest) { ManifestBuilderV3::ManifestServiceLocator.iiif_manifest_factory.new }

    before do
      builder.apply(manifest)
    end

    context "when viewing a ScannedMap resource with a valid coverage" do
      let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032).to_s }
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_map, coverage: coverage)
      end

      it "appends a navPlace extension to the Manifest" do
        features = manifest["navPlace"][:features][0]
        expect(manifest["navPlace"][:id]).to eq "http://www.example.com/concern/scanned_maps/#{resource.id}/manifest/feature-collection/1"
        expect(features[:id]).to eq "http://www.example.com/concern/scanned_maps/#{resource.id}/manifest/feature/1"
        expect(features[:geometry][:coordinates][0][0]).to eq [-69.856, 43.039]
      end
    end

    context "when viewing a ScannedMap resource with a non-valid coverage" do
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_map)
      end

      it "does not append a navPlace extension to the Manifest" do
        expect(manifest["navPlace"]).to be_nil
      end
    end

    context "when viewing a non-ScannedMap resource" do
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_resource)
      end

      it "does not append a navPlace extension to the Manifest" do
        expect(manifest["navPlace"]).to be_nil
      end
    end
  end
end
