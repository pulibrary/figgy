# frozen_string_literal: true
require "rails_helper"

RSpec.describe DspaceIngester do
  subject(:dspace_ingester) { described_class.new(handle: handle) }
  let(:handle) { "88435/dsp01w6634629" }

  describe "#ingest!" do
    xit "ingests the new resource" do
    end
  end

  describe "#id" do
    let(:id) { dspace_ingester.id }
    let(:headers) do
      {
        "Accept:": "application/json"
      }
    end
    let(:response_body) do
      {
        "id": "test-id"
      }.to_json
    end

    before do
      stub_request(:get,
                   "https://dataspace.princeton.edu/rest/handle/88435/dsp01w6634629").to_return(
                    status: 200,
                    headers: headers,
                    body: response_body
                  )
    end

    it "retrieves the ID from the API response" do
      expect(id).to eq("test-id")
    end
  end

  describe "#bitstreams" do
    let(:headers) do
      {
        "Accept:": "application/json"
      }
    end
    let(:item_response) do
      {
        "id": "test-id"
      }.to_json
    end
    let(:bitstream_response) do
      [
        {
          "name" => "test-name",
          "sequenceId" => "test-sequence-id"
        }
      ]
    end
    let(:bitstreams) { dspace_ingester.bitstreams }

    before do
      stub_request(:get,
                   "https://dataspace.princeton.edu/rest/items/test-id/bitstreams?limit=20&offset=0").to_return(
                   status: 200,
                   headers: headers,
                   body: bitstream_response.to_json
                 )
      stub_request(:get,
                   "https://dataspace.princeton.edu/rest/handle/88435/dsp01w6634629").to_return(
                   status: 200,
                   headers: headers,
                   body: item_response
                 )
    end

    it "retrieves the bitstreams from the API response" do
      expect(bitstreams).to eq(bitstream_response)
    end
  end
end
