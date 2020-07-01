# frozen_string_literal: true
require "rails_helper"

RSpec.describe Cdl::EligibleItemService do
  describe ".item_ids" do
    context "on_cdl is null" do
      before do
        stub_request(:get, "https://bibdata.princeton.edu/#{bib_id}/items")
          .to_return(status: 200,
                     body: file_fixture("bibdata/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
      end
      let(:bib_id) { "7214786" }

      it "will return an empty array if the on_cdl is null" do
        expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
      end
    end

    context "on_cdl is missing" do
      before do
        stub_request(:get, "https://bibdata.princeton.edu/#{bib_id}/items")
          .to_return(status: 200,
                     body: file_fixture("bibdata/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
      end
      let(:bib_id) { "7214787" }

      it "will return an empty array if the on_cdl is missing" do
        expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
      end
    end

    context "querying a suppressed bib" do
      before do
        stub_request(:get, "https://bibdata.princeton.edu/#{bib_id}/items")
          .to_return(status: 404,
                     body: {}.to_json, headers: { "Content-Type" => "application/json" })
      end
      let(:bib_id) { "11174664" }
      it "will return an empty array" do
        expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
      end
    end

    context "a bib_id with items in more than one locations" do
      before do
        stub_request(:get, "https://bibdata.princeton.edu/#{bib_id}/items")
          .to_return(status: 200,
                     body: file_fixture("bibdata/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
      end
      let(:bib_id) { "1377084" }
      it "returns only the cdl charged items" do
        expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq [1_666_779, 1_666_780, 1_666_781]
      end
    end
  end
end
