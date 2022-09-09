# frozen_string_literal: true
require "rails_helper"

describe VoyagerUpdater::Dump do
  subject(:dump) { described_class.new(url) }
  let(:url) { "http://example.com" }
  let(:data) do
    {
      "ids" => {
        "update_ids" => ["123456", "4609321"]
      }
    }
  end

  before do
    stub_request(:get, url)
      .to_return(body: data.to_json)
  end

  describe ".new" do
    it "constructs the object" do
      expect(dump.url).to eq(url)
    end
  end

  describe "#update_ids" do
    it "retrieves the bib. IDs for records which Voyager marked as updated" do
      expect(dump.update_ids).to eq(["123456", "4609321"])
    end
  end

  describe "#ids_needing_updated" do
    let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456") }
    let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "4609321") }

    before do
      stub_catalog(bib_id: "123456")
      stub_catalog(bib_id: "4609321")

      resource1
      resource2
    end
    it "retrieves the IDs for the resources which have the bib. IDs in their metadata" do
      expect(dump.ids_needing_updated).to eq([resource1.id.to_s, resource2.id.to_s])
    end
  end
end
