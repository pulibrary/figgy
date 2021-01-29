# frozen_string_literal: true
require "rails_helper"

describe PulMetadataServices::Client do
  let(:content_type_marc_xml) { "application/marcxml+xml" }

  before do
    stub_bibdata(bib_id: "4609321", content_type: content_type_marc_xml)
    stub_pulfa(pulfa_id: "AC044_c0003")
    stub_pulfa(pulfa_id: "RBD1_c13076")
    stub_aspace(pulfa_id: "MC001.01_c000001")
  end

  describe ".retrieve" do
    context "with a Voyager-like id" do
      let(:id) { "4609321" }
      let(:source) { file_fixture("bibdata/4609321.mrx").read }
      let(:full_source) { source }
      it "makes requests to Voyager" do
        expect(described_class.retrieve(id).source).to eq source
        expect(described_class.retrieve(id).full_source).to eq full_source
      end
    end
    context "with a Pulfa-like id" do
      let(:id) { "AC044_c0003" }
      let(:source) { file_fixture("pulfa/AC044/c0003.xml").read }
      let(:full_source) { file_fixture("pulfa/AC044/c0003_full.xml").read }
      it "makes requests to PULFA" do
        output = described_class.retrieve("AC044_c0003")
        expect(output.source).to eq source
        expect(output.full_source).to eq full_source
      end
      it "makes requests to aspace first" do
        output = described_class.retrieve("MC001.01_c000001")
        attributes = output.attributes
        expect(attributes[:title]).to eq ["Series 1: Reel Contents - American Civil Liberties Union Microfilm"]
        expect(attributes[:extent]).to eq ["12 boxes", "44 items", "5 Reels", "1881 Volumes"]
        expect(attributes[:date_created]).to eq ["1912-1950"]
      end
    end
    context "with a Pulfa-like id, when the metadata contains non-ASCII characters" do
      let(:id) { "RBD1_c13076" }
      let(:source) { file_fixture("pulfa/RBD1/c13076.xml").read }
      it "makes requests to PULFA and parses character encoding correctly" do
        expect(described_class.retrieve(id).source).to eq source
      end
    end
  end

  describe ".retrieve_from_bibdata" do
    let(:id) { "4609321" }
    let(:source) { file_fixture("bibdata/4609321.mrx").read }
    it "makes requests to Voyager" do
      expect(described_class.retrieve_from_bibdata(id)).to eq source
    end
  end
end
