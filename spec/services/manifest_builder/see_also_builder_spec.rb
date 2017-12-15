# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestBuilder::SeeAlsoBuilder do
  describe '#apply' do
    let(:builder) { described_class.new(scanned_resource) }
    let(:manifest) { IIIF::Presentation::Manifest.new }
    let(:decorated) { ScannedResourceDecorator.new(scanned_resource) }
    let(:remote_record_class) { class_double(RemoteRecord).as_stubbed_const }
    let(:remote_record_response) { instance_double(Faraday::Response) }

    before do
      allow(remote_record_class).to receive(:source_metadata_url).with('4609321').and_return("https://bibdata.princeton.edu/bibliographic/4609321")
      allow(remote_record_class).to receive(:source_metadata_url).with('AC044_c0003').and_return("https://findingaids.princeton.edu/collections/AC044/c0003.xml?scope=record")
      allow(remote_record_class).to receive(:retrieve).and_return(remote_record_response)
      allow(remote_record_response).to receive(:success?).and_return(true)
      builder.apply(manifest)
    end

    context 'when viewing a Scanned Resource with Voyager source ID' do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         source_metadata_identifier: "4609321")
      end

      it 'appends the transformed metadata to the Manifest' do
        expect(manifest.see_also).to be_a Array
        expect(manifest.see_also.length).to eq(2)
        expect(manifest.see_also.first).to include "@id" => "http://www.example.com/catalog/#{scanned_resource.id}.jsonld", "format" => "application/ld+json"
        expect(manifest.see_also.last).to include "@id" => 'https://bibdata.princeton.edu/bibliographic/4609321', "format" => "text/xml"
      end
    end

    context 'when viewing a Scanned Resource with PULFA source ID' do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         source_metadata_identifier: "AC044_c0003")
      end

      it 'appends the transformed metadata to the Manifest' do
        expect(manifest.see_also).to be_a Array
        expect(manifest.see_also.length).to eq(2)
        expect(manifest.see_also.first).to include "@id" => "http://www.example.com/catalog/#{scanned_resource.id}.jsonld", "format" => "application/ld+json"
        expect(manifest.see_also.last).to include "@id" => 'https://findingaids.princeton.edu/collections/AC044/c0003.xml?scope=record', "format" => "text/xml"
      end
    end
  end
end
