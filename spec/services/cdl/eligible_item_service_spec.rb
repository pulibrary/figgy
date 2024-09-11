# frozen_string_literal: true
require "rails_helper"

RSpec.describe CDL::EligibleItemService do
  context "when CDL is disabled" do
    before do
      allow(Figgy).to receive(:cdl_enabled?).and_return(false)
    end

    describe ".item_ids" do
      context "cdl is true" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 200,
                       body: file_fixture("files/catalog/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "9965126093506421" }

        it "returns an empty array" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
        end
      end
    end
  end
  context "when CDL is enabled" do
    before do
      allow(Figgy).to receive(:cdl_enabled?).and_return(true)
    end

    describe ".item_ids" do
      context "when given a component ID" do
        it "returns an empty array" do
          expect(described_class.item_ids(source_metadata_identifier: "AC101_C002")).to eq []
        end
      end

      context "alma is down" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 500,
                       body: "500", headers: { "Content-Type" => "application/json" })
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/99#{bib_id}3506421/items").to_return(status: 500, body: "500", headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "9972147863506421" }
        it "will return an empty array" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
        end
      end

      context "no item is on CDL" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 200,
                       body: file_fixture("files/catalog/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/99#{bib_id}3506421/items").to_return(status: 500, body: "500", headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "9972147873506421" }

        it "will return an empty array" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
        end
      end

      context "querying a suppressed bib" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 404,
                       body: {}.to_json, headers: { "Content-Type" => "application/json" })
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/99#{bib_id}3506421/items").to_return(status: 500, body: "500", headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "11174664" }
        it "will return an empty array" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
        end
      end

      context "querying a bib with no items" do
        before do
          html_body = "Record #{bib_id} not found or suppressed"
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 404,
                       body: html_body, headers: { "Content-Type" => "application/json" })
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/99#{bib_id}3506421/items").to_return(status: 500, body: "500", headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "11174664" }
        it "will return an empty array" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
        end
      end

      context "a bib_id with items in more than one locations" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 200,
                       body: file_fixture("files/catalog/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "9913770843506421" }
        it "returns only the cdl charged items" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq [1_666_779, 1_666_780, 1_666_781]
        end
      end

      context "several nested holdings and locations" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 200,
                       body: file_fixture("files/catalog/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "999227203506421" }
        it "returns the CDL charged items" do
          expect(described_class.item_ids(source_metadata_identifier: "999227203506421")).not_to be_blank
        end
      end

      context "cdl is true" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 200,
                       body: file_fixture("files/catalog/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "9965126093506421" }

        it "returns the item pid" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq ["23202918780006421"]
        end

        it "caches the response for 5 minutes" do
          allow(Rails.cache).to receive(:fetch).and_call_original

          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to be_present

          expect(Rails.cache).to have_received(:fetch).with("cdl_item_ids_#{bib_id}", expires_in: 5.minutes)
        end
      end

      context "cdl is false" do
        before do
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/items")
            .to_return(status: 200,
                       body: file_fixture("files/catalog/#{bib_id}.json").read, headers: { "Content-Type" => "application/json" })
          stub_request(:get, "https://bibdata.princeton.edu/bibliographic/99#{bib_id}3506421/items").to_return(status: 500, body: "500", headers: { "Content-Type" => "application/json" })
        end
        let(:bib_id) { "9968643943506421" }

        it "will return an empty array" do
          expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
        end
      end
    end
  end
end
