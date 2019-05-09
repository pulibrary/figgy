# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticsImportService::TinyTdsAdapter do
  let(:adapter) { described_class.new(dbhost: nil, dbport: nil, dbuser: nil, dbpass: nil) }
  let(:client) { instance_double TinyTds::Client }
  let(:result) { instance_double TinyTds::Result }
  before do
    allow(TinyTds::Client).to receive(:new).and_return(client)
    allow(client).to receive(:execute).and_return(result)
    allow(result).to receive(:to_a).and_return([])
  end

  describe "#execute" do
    it "returns an array" do
      expect(adapter.execute(query: "an actual SQL query")).to eq []
    end
  end
end
