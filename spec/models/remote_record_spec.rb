# frozen_string_literal: true
require "rails_helper"

RSpec.describe RemoteRecord, type: :model do
  describe ".retrieve" do
    context "with a Voyager record ID" do
      it "constructs a RemoteRecord instance" do
        expect(described_class.retrieve("4609321")).to be_a described_class
      end
    end

    context "with a PULFA record ID" do
      it "constructs a PulfaRecord instance" do
        expect(described_class.retrieve("AC044_c0003")).to be_a RemoteRecord::PulfaRecord
      end
    end
  end

  describe ".bibdata?" do
    context "with a Voyager record ID" do
      it "validates that this is a bib. ID" do
        expect(described_class.bibdata?("4609321")).to be_truthy
      end
    end

    context "with an Alma ID" do
      it "is true" do
        expect(described_class.bibdata?("994241263506421")).to be_truthy
      end
    end

    context "with a tiny ID" do
      it "is not true" do
        expect(described_class.bibdata?("1")).to be_falsey
      end
    end

    context "with a PULFA record ID" do
      it "validates that this is a not a bib. ID" do
        expect(described_class.bibdata?("AC044_c0003")).to be_falsy
      end
    end
  end

  describe ".pulfa?" do
    it "handles a lot of variants" do
      expect(described_class.pulfa?("RCPXG-5830371.2_c0001")).to be true
      expect(described_class.pulfa?("C0744.04_c0082")).to be true
      expect(described_class.pulfa?("C0723.1-47_c0276")).to be true
      expect(described_class.pulfa?("C0723.306e_c013")).to be true
      expect(described_class.pulfa?("MC001.03.03_c0171")).to be true
      expect(described_class.pulfa?("MC001")).to be true
    end

    it "does not allow slashes" do
      expect(described_class.pulfa?("MC016/c11318")).to be false
    end

    it "is false for bib ids" do
      expect(described_class.pulfa?("123456")).to be false
    end
  end

  describe ".pulfa_collection" do
    it "handles a lot of variants" do
      expect(described_class.pulfa_collection("RCPXG-5830371.2_c0001")).to eq "RCPXG-5830371.2"
      expect(described_class.pulfa_collection("C0744.04_c0082")).to eq "C0744.04"
      expect(described_class.pulfa_collection("C0723.1-47_c0276")).to eq "C0723.1-47"
      expect(described_class.pulfa_collection("C0723.306e_c013")).to eq "C0723.306e"
      expect(described_class.pulfa_collection("MC001.03.03_c0171")).to eq "MC001.03.03"
      expect(described_class.pulfa_collection("MC016_c11318")).to eq "MC016"
      expect(described_class.pulfa_collection("MC001")).to eq "MC001"
    end

    it "does not allow slashes" do
      expect(described_class.pulfa_collection("MC016/c11318")).to be nil
    end
  end

  describe ".pulfa_component" do
    it "handles a lot of variants" do
      expect(described_class.pulfa_component("RCPXG-5830371.2_c0001")).to eq "c0001"
      expect(described_class.pulfa_component("C0744.04_c0082")).to eq "c0082"
      expect(described_class.pulfa_component("C0723.1-47_c0276")).to eq "c0276"
      expect(described_class.pulfa_component("C0723.306e_c013")).to eq "c013"
      expect(described_class.pulfa_component("MC001.03.03_c0171")).to eq "c0171"
      expect(described_class.pulfa_component("MC016_c11318")).to eq "c11318"
      expect(described_class.pulfa_component("MC001")).to eq nil
    end

    it "does not allow slashes" do
      expect(described_class.pulfa_component("MC016/c11318")).to be nil
    end
  end

  describe ".source_metadata_url" do
    context "with a Voyager record ID" do
      it "provides a link to the catalog record" do
        expect(described_class.source_metadata_url("4609321")).to eq "https://bibdata.princeton.edu/bibliographic/4609321"
      end
    end

    context "with a PULFA record ID" do
      it "provides a link to the finding aid" do
        expect(described_class.source_metadata_url("AC044_c0003")).to eq "https://findingaids.princeton.edu/catalog/AC044_c0003.xml"
      end
    end
  end

  describe ".record_url" do
    context "with a Voyager record ID" do
      it "validates that this is not a bib. ID" do
        expect(described_class.record_url("4609321")).to eq "https://catalog.princeton.edu/catalog/4609321"
      end
    end

    context "with a PULFA record ID" do
      it "validates that this is a bib. ID" do
        expect(described_class.record_url("AC044_c0003")).to eq "https://findingaids.princeton.edu/catalog/AC044_c0003"
      end
    end

    context "when passed nil" do
      it "returns nil" do
        expect(described_class.record_url(nil)).to eq nil
      end
    end
  end
end
