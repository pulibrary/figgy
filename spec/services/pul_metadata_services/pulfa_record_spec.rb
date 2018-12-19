# frozen_string_literal: true
require "rails_helper"

describe PulMetadataServices::PulfaRecord do
  subject(:pulfa_record) { described_class.new(source) }

  let(:pulfa_id) { "AC123_c00004" }
  let(:source) { file_fixture("pulfa/#{pulfa_id}.xml").read }

  describe "#attributes" do
    it "works" do
      expected = {
        title: ["19th Century Catalog and Correspondence, Pre-Vinton, 1811-"],
        created: ["1865-01-01T00:00:00Z/1865-12-31T23:59:59Z"],
        creator: ["Princeton University. Library. Dept. of Rare Books and Special Collections"],
        publisher: ["Princeton University. Library. Dept. of Rare Books and Special Collections"],
        memberOf: [{ title: "Princeton University Library Records", identifier: "AC123" }],
        date_created: ["circa 1865"],
        container: ["Box 1, Folder 2"],
        extent: ["1 folder"],
        heldBy: ["mudd"],
        language: ["eng"]
      }
      expect(pulfa_record.attributes).to eq expected
    end
  end

  describe "#collection?" do
    it "knows it's not a collection" do
      expect(pulfa_record.collection?).to be false
    end
  end

  context "with missing data" do
    let(:pulfa_id) { "AC057_c18" }

    describe "#attributes" do
      it "doesn't fail" do
        expect { pulfa_record.attributes }.not_to raise_error
      end

      it "returns nil for the missing fields" do
        expect(pulfa_record.attributes[:language]).to be nil
        expect(pulfa_record.attributes[:container]).to eq ["Box 2"]
      end
    end
  end

  context "with DSC container approach" do
    let(:pulfa_id) { "C0967_c0001" }

    describe "#attributes" do
      it "works" do
        expected = {
          title: ["Abdura Makedonias"],
          creator: ["Lampakēs, Geōrgios, 1854-1914."],
          publisher: ["Lampakēs, Geōrgios, 1854-1914."],
          created: ["1902-01-01T00:00:00Z/1902-12-31T23:59:59Z"],
          date_created: ["1902"],
          memberOf: [{ title: "Byzantine and post-Byzantine Inscriptions Collection", identifier: "C0967" }],
          container: ["Box 1, Folder 1"],
          extent: ["1 folder"],
          heldBy: ["mss"],
          language: ["gre"]
        }
        expect(pulfa_record.attributes).to eq expected
      end
    end
  end

  context "collection record" do
    let(:pulfa_id) { "C0652" }

    it "knows it's a collection" do
      expect(pulfa_record.collection?).to be true
    end

    describe "#attributes" do
      it "returns attributes hash" do
        expected = {
          title: ["Emir Rodriguez Monegal Papers"],
          created: ["1941-01-01T00:00:00Z/1985-12-31T23:59:59Z"],
          date_created: ["1941-1985"],
          extent: ["11 linear feet"],
          heldBy: ["mss"],
          language: ["spa"]
        }
        expect(pulfa_record.attributes).to eq expected
      end
    end
  end

  context "with a record for a MediaResource" do
    subject(:pulfa_record) { described_class.new(source, MediaResource.new) }
    let(:pulfa_id) { "C0652_c0377" }
    let(:source) { file_fixture("pulfa/C0652/c0377.xml").read }

    describe "#attributes" do
      it "returns attributes hash" do
        expect(pulfa_record.attributes).to include title: ["Emir Rodriguez Monegal Papers"]
        expect(pulfa_record.attributes).to include created: ["1941-01-01T00:00:00Z/1985-12-31T23:59:59Z"]
        expect(pulfa_record.attributes).to include date_created: ["1941-1985"]
        expect(pulfa_record.attributes).to include extent: ["11 linear feet"]
        expect(pulfa_record.attributes).to include heldBy: ["mss"]
        expect(pulfa_record.attributes).to include language: ["spa"]
      end
    end
  end
end
