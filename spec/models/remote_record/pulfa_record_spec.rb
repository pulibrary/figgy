# frozen_string_literal: true
require "rails_helper"

describe RemoteRecord::PulfaRecord, type: :model do
  subject(:pulfa_record) { described_class.new(source_metadata_identifier) }
  let(:source_metadata_identifier) { "C0652" }

  before do
    stub_aspace(pulfa_id: "C0652")
    stub_aspace(pulfa_id: "C0652_c0377")
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

  describe "#client_result" do
    it "retrieves the record data and constructs a PulMetadataServices object" do
      expect(pulfa_record.client_result).to be_a PulMetadataServices::AspacePulfaRecord
    end
  end
end
