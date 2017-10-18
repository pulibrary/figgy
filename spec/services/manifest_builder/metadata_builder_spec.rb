# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestBuilder::MetadataBuilder do
  describe '#apply' do
    let(:manifest) { IIIF::Presentation::Manifest.new }

    context 'when viewing a new Scanned Resource' do
      let(:builder) { described_class.new(scanned_resource) }
      let(:decorated) { instance_double(ScannedResourceDecorator) }
      let(:scanned_resource) { instance_double(ScannedResource) }

      before do
        allow(scanned_resource).to receive(:decorate).and_return(decorated)
        allow(decorated).to receive(:iiif_manifest_attributes).and_return(
          title: ['test title'],
          identifier: ['http://arks.princeton.edu/ark:/88435/5m60qr98h'],
          pdf_type: ['Gray'],
          created: ['1465-01-01T00:00:00Z/1480-12-31T23:59:59Z'],
          updated: ['1470-06-07T01:02:03Z']
        )
        builder.apply(manifest)
      end

      it 'appends the transformed metadata to the Manifest' do
        expect(manifest.metadata).to be_an Array
        expect(manifest.metadata).to include label: "Title", value: ["test title"]
        expect(manifest.metadata).to include label: "Identifier", value: \
          ["<a href='http://arks.princeton.edu/ark:/88435/5m60qr98h' alt='Identifier'>http://arks.princeton.edu/ark:/88435/5m60qr98h</a>"]
        expect(manifest.metadata).to include label: "PDF Type", value: ["Gray"]
        expect(manifest.metadata).to include label: "Created", value: ["1465-1480"]
        expect(manifest.metadata).to include label: "Updated", value: ["06/07/1470"]
      end
    end

    context 'when viewing an Ephemera Project' do
      let(:builder) { described_class.new(ephemera_project) }
      let(:decorated) { instance_double(EphemeraProjectDecorator) }
      let(:ephemera_project) { instance_double(EphemeraProject) }

      before do
        allow(ephemera_project).to receive(:decorate).and_return(decorated)
        allow(decorated).to receive(:iiif_manifest_attributes).and_return(
          exhibit: "lae-d957"
        )
        builder.apply(manifest)
      end

      it 'appends the transformed metadata to the Manifest' do
        expect(manifest.metadata).to be_an Array
        expect(manifest.metadata).to include label: "Exhibit", value: "lae-d957"
      end
    end
  end
end
