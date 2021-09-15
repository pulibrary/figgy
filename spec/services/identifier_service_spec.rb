# frozen_string_literal: true
require "rails_helper"

RSpec.describe IdentifierService do
  let(:ark) { "ark:/88435/x1234567" }
  let(:minter) { class_double("Ezid::Identifier") }
  let(:identifier) { instance_double("Ezid::Identifier") }
  let(:base_metadata) { { dc_publisher: "Princeton University Library", dc_title: "Title", dc_type: "Text" } }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  before do
    stub_ezid(shoulder: "88435", blade: "x1234567")
  end

  context "when there is an existing identifier" do
    let(:metadata) { base_metadata.merge(target: "https://catalog.princeton.edu/catalog/123456#{obj.id}#view") }
    let(:obj) { FactoryBot.build :scanned_resource, source_metadata_identifier: "123456", identifier: ark }

    before do
      stub_bibdata(bib_id: "123456")
      allow(described_class).to receive(:minter).and_return(minter)
      allow(described_class).to receive(:minter_user).and_return("pudiglib")
      allow(minter).to receive(:modify)
    end

    it "updates the ark" do
      described_class.mint_or_update(resource: obj)
      expect(minter).to have_received(:modify).with(ark, metadata)
      expect(obj.identifier.first).to eq(ark)
    end

    context "and the identifier currently points at PULFA" do
      let(:ark) { "ark:/88435/47429918s" }
      let(:minter) { class_double(Ezid::Identifier) }
      let(:minted_id) { instance_double(Ezid::Identifier) }
      let(:new_ark) { "ark:/99999/fk4345678" }
      let(:metadata) { base_metadata.merge(target: "http://findingaids.princeton.edu/collections/#{cid}") }
      before do
        stub_ezid(shoulder: "88435", blade: "47429918s", location: "https://findingaids.princeton.edu/bla")
        allow(minted_id).to receive(:id).and_return(new_ark)
        allow(minter).to receive(:mint).and_return(minted_id)
        described_class.mint_or_update(resource: obj)
      end
      it "does not update the ARK" do
        expect(minter).not_to have_received(:modify)
        expect(minter).not_to have_received(:mint)
        expect(obj.identifier).to eq([ark])
      end
    end
  end

  context "when there is an imported identifier" do
    let(:obj) do
      resource = FactoryBot.build :scanned_resource, source_metadata_identifier: "10001789"
      change_set = ChangeSet.for(resource)
      change_set.validate(source_metadata_identifier: "10001789")
      change_set_persister.save(change_set: change_set)
    end
    let(:change_set_persister) do
      ChangeSetPersister.new(
        metadata_adapter: Valkyrie.config.metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
    let(:base_metadata) { { dc_publisher: "Princeton University Library", dc_title: "Cameroons under United Kingdom Trusteeship 1949", dc_type: "Text" } }
    let(:metadata) { base_metadata.merge(target: "https://catalog.princeton.edu/catalog/10001789#view") }
    let(:ark) { "ark:/88435/jq085p05h" }

    before do
      stub_bibdata(bib_id: "10001789")
      stub_ezid(shoulder: "88435", blade: "jq085p05h")
      allow(described_class).to receive(:minter).and_return(minter)
      allow(described_class).to receive(:minter_user).and_return("pudiglib")
      allow(minter).to receive(:modify)
    end

    it "updates the ark" do
      described_class.mint_or_update(resource: obj)
      expect(minter).to have_received(:modify).with(ark, metadata)
      expect(obj.identifier).to eq([ark])
      expect(obj.imported_metadata.first.identifier.first).to eq("http://arks.princeton.edu/#{ark}")
    end
  end

  context "when the identifier is blank" do
    before do
      allow(described_class).to receive(:minter).and_return(minter)
      allow(minter).to receive(:mint).and_return(identifier)
      allow(identifier).to receive(:id).and_return(ark)
    end

    context "with a bibdata source_metadata_identifier" do
      let(:bib) { "123456" }
      let(:metadata) { base_metadata.merge(target: "https://catalog.princeton.edu/catalog/#{bib}#view") }
      let(:obj) { FactoryBot.build :scanned_resource, source_metadata_identifier: bib }

      before do
        stub_bibdata(bib_id: "123456")
      end

      it "links to OrangeLight" do
        described_class.mint_or_update(resource: obj)
        expect(minter).to have_received(:mint).with(metadata)
      end
    end

    context "with a pulfa source_metadata_identifier" do
      let(:cid) { "MC016_c9616" }
      let(:metadata) { base_metadata.merge(target: "http://findingaids.princeton.edu/collections/#{cid.tr('_', '/')}") }
      let(:obj) { FactoryBot.build :scanned_resource, source_metadata_identifier: cid }

      before do
        stub_pulfa(pulfa_id: "MC016_c9616")
      end

      it "links to OrangeLight" do
        described_class.mint_or_update(resource: obj)
        expect(minter).to have_received(:mint).with(metadata)
      end
    end

    context "without a source_metadata_identifier" do
      let(:metadata) { base_metadata.merge(target: "http://www.example.com/catalog/#{obj.id}") }
      let(:obj) { FactoryBot.create :scanned_resource, source_metadata_identifier: nil }
      it "links to OrangeLight" do
        described_class.mint_or_update(resource: obj)
        expect(minter).to have_received(:mint).with(metadata)
      end
    end
  end

  context "with a geospatial resource" do
    let(:metadata) { base_metadata.merge(target: "https://maps.princeton.edu/catalog/princeton-x1234567") }

    before do
      allow(described_class).to receive(:minter).and_return(minter)
      allow(minter).to receive(:mint).and_return(identifier)
      allow(minter).to receive(:modify)
      allow(identifier).to receive(:id).and_return(ark)
      allow(described_class).to receive(:minter_user).and_return("pudiglib")
    end

    context "with a blank identifier" do
      let(:obj) { FactoryBot.create :scanned_map }

      it "mints an ARK then modifies the metadata with a link to Pulmap" do
        described_class.mint_or_update(resource: obj)
        expect(minter).to have_received(:mint)
        expect(minter).to have_received(:modify).with(ark, metadata)
      end
    end

    context "with an existing identifier" do
      let(:obj) { FactoryBot.create :scanned_map, identifier: ark }

      it "udpates the ARK metadata " do
        described_class.mint_or_update(resource: obj)
        expect(minter).not_to have_received(:mint)
        expect(minter).to have_received(:modify).with(ark, metadata)
      end
    end
  end

  context "integration test" do
    let(:metadata) { base_metadata.merge(target: "http://example.com/catalog/#{obj.id}") }
    let(:obj) { FactoryBot.create :scanned_resource, source_metadata_identifier: nil }
    let(:shoulder) { "99999/fk4" }
    let(:blade) { "123456" }

    before do
      stub_ezid(shoulder: shoulder, blade: blade)
    end

    it "mints an ARK" do
      described_class.mint_or_update(resource: obj)
      expect(obj.identifier.first).to eq("ark:/#{shoulder}#{blade}")
    end

    it "uses a test account" do
      expect(described_class.send(:minter_user)).to eq("apitest")
    end
  end
end
