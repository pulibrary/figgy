# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManifestBuilder::ManifestServiceLocator do
  describe ".see_also_builder" do
    it "returns the class for building manifest see also links" do
      expect(described_class.see_also_builder).to eq ManifestBuilder::SeeAlsoBuilder
    end
  end

  describe ".license_builder" do
    it "returns the class for building manifest license" do
      expect(described_class.license_builder).to eq ManifestBuilder::LicenseBuilder
    end
  end

  describe ".manifest_builders" do
    it "returns a composite builder factory" do
      expect(described_class.manifest_builders).to be_a IIIFManifest::ManifestBuilder::CompositeBuilderFactory
    end
  end
end
