# frozen_string_literal: true
require "rails_helper"

describe RemoteRecord::PulfaRecord, type: :model do
  subject(:pulfa_record) { described_class.new(source_metadata_identifier) }
  let(:source_metadata_identifier) { "C0652" }

  before do
    stub_findingaid(pulfa_id: "C0652")
    stub_findingaid(pulfa_id: "C0652_c0377")
  end

  describe ".new" do
    it "constructs the object" do
      expect(pulfa_record.source_metadata_identifier).to eq(source_metadata_identifier)
    end
  end

  describe "#attributes" do
    it "retrieves the attributes from the remote bibligraphic record" do
      expect(pulfa_record.attributes).to be_a Hash
      expect(pulfa_record.attributes).to include title: ["Emir Rodriguez Monegal Papers"]
      expect(pulfa_record.attributes).to include language: ["spa"]
      expect(pulfa_record.attributes).to include date_created: ["1941-1985, bulk 1965/1968"]
      expect(pulfa_record.attributes).to include extent: ["24 boxes"]
      expect(pulfa_record.attributes).to include heldBy: ["Firestone Library"]
      expect(pulfa_record.attributes).to include :source_metadata
      expect(pulfa_record.attributes[:source_metadata]).not_to be_empty
    end
  end

  describe "#success?" do
    it "indicates whether or not the record data could be retrieved over the HTTP" do
      expect(pulfa_record.success?).to be true
    end
  end

  describe ".attributes" do
    context "with a Pulfa-like id" do
      let(:id) { "MC001.01_c000001" }
      it "parses pulfalight records" do
        stub_findingaid(pulfa_id: "MC001.01_c000001")
        findingaids_record = described_class.new("MC001.01_c000001")
        attributes = findingaids_record.attributes
        expect(attributes[:title]).to eq ["Series 1: Reel Contents - American Civil Liberties Union Microfilm"]
        expect(attributes[:extent]).to eq ["12 boxes", "44 items", "5 Reels", "1881 Volumes"]
        expect(attributes[:date_created]).to eq ["1912-1950"]
      end
    end
    context "when the metadata contains non-ASCII characters" do
      let(:id) { "RBD1_c13076" }
      let(:source) { file_fixture("files/pulfa/aspace/RBD1_c13076.json").read }
      it "reads character encoding correctly" do
        stub_findingaid(pulfa_id: "RBD1_c13076")
        expect(described_class.new(id).source).to eq source
      end
    end
  end
end
