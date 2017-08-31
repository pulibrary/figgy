# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IdentifierService do
  let(:ark) { 'ark:88435/x1234567' }
  let(:minter) { class_double('Ezid::Identifier') }
  let(:identifier) { instance_double('Ezid::Identifier') }
  let(:base_metadata) { { dc_publisher: 'Princeton University Library', dc_title: 'Title', dc_type: 'Text' } }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }

  context "when there is an existing identifier" do
    let(:metadata) { base_metadata.merge(target: "https://pulsearch.princeton.edu/catalog/123456#{obj.id}#view") }
    let(:obj) { FactoryGirl.build :scanned_resource, source_metadata_identifier: '123456', identifier: ark }

    before do
      stub_bibdata(bib_id: '123456')
      allow(described_class).to receive(:minter).and_return(minter)
      allow(described_class).to receive(:minter_user).and_return('pudiglib')
      allow(minter).to receive(:modify)
    end

    it "updates the ark" do
      described_class.mint_or_update(resource: obj)
      expect(minter).to have_received(:modify).with(ark, metadata)
      expect(obj.identifier.first).to eq(ark)
    end
  end

  context "when the identifier is blank" do
    before do
      allow(described_class).to receive(:minter).and_return(minter)
      allow(minter).to receive(:mint).and_return(identifier)
      allow(identifier).to receive(:id).and_return(ark)
    end

    context "with a bibdata source_metadata_identifier" do
      let(:bib) { '123456' }
      let(:metadata) { base_metadata.merge(target: "https://pulsearch.princeton.edu/catalog/#{bib}#view") }
      let(:obj) { FactoryGirl.build :scanned_resource, source_metadata_identifier: bib }

      before do
        stub_bibdata(bib_id: '123456')
      end

      it "links to OrangeLight" do
        described_class.mint_or_update(resource: obj)
        expect(minter).to have_received(:mint).with(metadata)
      end
    end

    context "with a pulfa source_metadata_identifier" do
      let(:cid) { 'MC016/c9616' }
      let(:metadata) { base_metadata.merge(target: "http://findingaids.princeton.edu/collections/#{cid}") }
      let(:obj) { FactoryGirl.build :scanned_resource, source_metadata_identifier: cid }

      before do
        stub_pulfa(pulfa_id: 'MC016/c9616')
      end

      it "links to OrangeLight" do
        described_class.mint_or_update(resource: obj)
        expect(minter).to have_received(:mint).with(metadata)
      end
    end

    context "without a source_metadata_identifier" do
      let(:metadata) { base_metadata.merge(target: "http://www.example.com/concern/scanned_resources/#{obj.id}") }
      let(:obj) { FactoryGirl.create :scanned_resource, id: '1234567', source_metadata_identifier: nil }
      it "links to OrangeLight" do
        described_class.mint_or_update(resource: obj)
        expect(minter).to have_received(:mint).with(metadata)
      end
    end
  end

  context "integration test" do
    let(:metadata) { base_metadata.merge(target: "http://example.com/concern/scanned_resources/#{obj.id}") }
    let(:obj) { FactoryGirl.create :scanned_resource, id: '1234567', source_metadata_identifier: nil }
    let(:shoulder) { '99999/fk4' }
    let(:blade) { '123456' }

    before do
      stub_ezid(shoulder: shoulder, blade: blade)
    end

    it "mints an ARK" do
      described_class.mint_or_update(resource: obj)
      expect(obj.identifier.first).to eq("ark:/#{shoulder}#{blade}")
    end

    it "uses a test account" do
      expect(described_class.send(:minter_user)).to eq('apitest')
    end
  end
end
