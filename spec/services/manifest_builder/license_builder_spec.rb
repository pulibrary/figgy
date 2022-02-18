# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManifestBuilder::LicenseBuilder do
  describe "#apply" do
    let(:builder) { described_class.new(scanned_resource) }
    let(:manifest) { ManifestBuilder::ManifestServiceLocator.iiif_manifest_factory.new }
    let(:decorated) { ScannedResourceDecorator.new(scanned_resource) }
    let(:scanned_resource) do
      FactoryBot.create_for_repository(:scanned_resource,
        rights_statement: RDF::URI("https://creativecommons.org/licenses/by-nc/4.0/"))
    end

    context "when viewing a new Scanned Resource" do
      before do
        builder.apply(manifest)
      end

      it "appends the transformed metadata to the Manifest" do
        expect(manifest["license"]).to eq "https://creativecommons.org/licenses/by-nc/4.0/"
      end
    end
  end
end
