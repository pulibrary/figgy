# frozen_string_literal: true
require "rails_helper"

describe PulMetadataServices::Client do
  let(:content_type_marc_xml) { "application/marcxml+xml" }

  before do
    stub_catalog(bib_id: "9946093213506421", content_type: content_type_marc_xml)
    stub_findingaid(pulfa_id: "RBD1_c13076")
    stub_findingaid(pulfa_id: "MC001.01_c000001")
  end

  describe ".retrieve" do
    context "with an Alma-like id" do
      let(:id) { "9946093213506421" }
      let(:source) { file_fixture("files/catalog/9946093213506421.mrx").read }
      let(:full_source) { source }
      it "makes requests to Alma" do
        expect(described_class.retrieve(id).source).to eq source
        expect(described_class.retrieve(id).full_source).to eq full_source
      end
    end
    context "with a Pulfa-like id" do
      let(:id) { "MC001.01_c000001" }
      it "makes requests to pulfalight" do
        output = described_class.retrieve("MC001.01_c000001")
        attributes = output.attributes
        expect(attributes[:title]).to eq ["Series 1: Reel Contents - American Civil Liberties Union Microfilm"]
        expect(attributes[:extent]).to eq ["12 boxes", "44 items", "5 Reels", "1881 Volumes"]
        expect(attributes[:date_created]).to eq ["1912-1950"]
      end
    end
    context "with a Pulfa-like id, when the metadata contains non-ASCII characters" do
      let(:id) { "RBD1_c13076" }
      let(:source) { file_fixture("files/pulfa/aspace/RBD1_c13076.json").read }
      it "makes requests to PULFA and parses character encoding correctly" do
        expect(described_class.retrieve(id).source).to eq source
      end
    end
  end

  describe ".retrieve_from_catalog" do
    let(:id) { "9946093213506421" }
    let(:source) { file_fixture("files/catalog/9946093213506421.mrx").read }
    it "makes requests to Alma" do
      expect(described_class.retrieve_from_catalog(id)).to eq source
    end
  end
end
