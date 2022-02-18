# frozen_string_literal: true

require "rails_helper"

describe PulMetadataServices::PulfaRecord::CollectionAttributes do
  subject(:collection_attributes) { described_class.new(data) }
  let(:pulfa_id) { "C0652" }
  let(:source) { file_fixture("pulfa/#{pulfa_id}.xml").read }
  let(:data) { Nokogiri::XML(source).remove_namespaces! }

  describe "#attributes" do
    it "retrieves the attributes in a Hash" do
      expect(collection_attributes.attributes).to be_a Hash
      expect(collection_attributes.attributes).to include(title: ["Emir Rodriguez Monegal Papers"])
      expect(collection_attributes.attributes).to include(language: ["spa"])
      expect(collection_attributes.attributes).to include(heldBy: ["mss"])
      expect(collection_attributes.attributes).to include(extent: ["11 linear feet"])
      expect(collection_attributes.attributes).to include(date_created: ["1941-1985"])
      expect(collection_attributes.attributes).to include(created: ["1941-01-01T00:00:00Z/1985-12-31T23:59:59Z"])
    end
  end

  describe "#data_root" do
    it "generates the root XPath for the EAD" do
      expect(collection_attributes.data_root).to eq "/archdesc"
    end
  end

  describe "#collections" do
    it "return an empty Array" do
      expect(collection_attributes.collections).to be_empty
    end
  end
end
