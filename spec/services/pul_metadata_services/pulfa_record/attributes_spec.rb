# frozen_string_literal: true

require "rails_helper"

describe PulMetadataServices::PulfaRecord::Attributes do
  subject(:attributes) { described_class.new(data) }
  let(:pulfa_id) { "C0967_c0001" }
  let(:source) { file_fixture("pulfa/#{pulfa_id}.xml").read }
  let(:data) { Nokogiri::XML(source).remove_namespaces! }

  describe "#collections" do
    it "return an empty Array" do
      expect(attributes.collections).to eq [title: "Byzantine and post-Byzantine Inscriptions Collection", identifier: "C0967"]
    end
  end
end
