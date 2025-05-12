# frozen_string_literal: true
require "rails_helper"

RSpec.describe DspaceCollectionIngester do
  subject(:ingester) { described_class.new(handle: handle, collection_ids: collection_ids) }

  let(:collection_handle) { "88435/dsp01testcollection" }
  let(:handle) { collection_handle }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:collection_ids) { [collection.id.to_s] }

  let(:logger) { Logger.new(STDOUT) }
  let(:dspace_api_token) { "secret" }
  let(:id) { ingester.id }

  let(:headers) do
    {
      "Accept:": "application/json"
    }
  end
  let(:oai_fixture_path) { Rails.root.join("spec", "fixtures", "dspace_ingest_oai.xml") }

  let(:collection_id) { "test-collection-id" }
  let(:item_id) { "test-id" }
  let(:mms_id) { "99125128447906421" }

  let(:catalog_request_url) { "https://catalog.princeton.edu/catalog.json?f%5Baccess_facet%5D%5B0%5D=Online&f%5Bpublisher%5D%5B0%5D=Alcuin%20Society&f%5Btitle%5D%5B0%5D=Alcuin%20Society%20newsletter,%20No.%2022&q=88435/dsp01test&search_field=electronic_access_1display" }
  let(:item_handle) { "88435/dsp01test" }

  before do
    stub_dspace_collection_requests(headers: headers, collection_id: collection_id, item_handle: item_handle)
  end

  describe "#ingest!" do
    before do
      stub_catalog(bib_id: mms_id)
      stub_dspace_item_requests(headers: headers, item_id: item_id, item_handle: item_handle)
      stub_dspace_catalog_requests(headers: headers, mms_id: mms_id, catalog_request_url: catalog_request_url)
      stub_dspace_oai_requests(headers: headers, item_handle: item_handle, oai_fixture_path: oai_fixture_path)

      allow(IngestDspaceAssetJob).to receive(:perform_later)
    end

    context "when authenticated with an API token" do
      let(:headers) do
        {
          "Rest-Dspace-Token" => "secret",
          "Accept" => "application/json"
        }
      end

      before do
        stub_dspace_bitstream_requests(headers: headers, item_id: item_id)
      end

      it "enqueues a new resource for ingestion" do
        ingester.ingest!

        expect(IngestDspaceAssetJob).to have_received(:perform_later).with(
          hash_including(
            handle: item_handle
          )
        )
      end

      context "when providing default resource attributes" do
        it "enqueues a new resource for ingestion with the attributes" do
          ingester.ingest!(member_of_collection_ids: collection_ids)

          expect(IngestDspaceAssetJob).to have_received(:perform_later).with(hash_including(member_of_collection_ids: collection_ids))
        end
      end

      context "when the MMS ID cannot be found using the ARK, " do
        before do
          stub_dspace_catalog_missing_requests(headers: headers, catalog_request_url: catalog_request_url)
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester.ingest!

          expect(IngestDspaceAssetJob).not_to have_received(:perform_later).with(
            hash_including(
              source_metadata_identifier: mms_id
            )
          )
          expect(IngestDspaceAssetJob).to have_received(:perform_later).with(
            hash_including(
              handle: item_handle
            )
          )
        end
      end

      context "when a bib. record can be found using the ARK but it does not have the `electronic_portfolio_s` attribute" do
        before do
          stub_dspace_invalid_catalog_requests(headers: headers, catalog_request_url: catalog_request_url, mms_id: mms_id)
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester.ingest!

          expect(IngestDspaceAssetJob).not_to have_received(:perform_later).with(
            hash_including(
              source_metadata_identifier: mms_id
            )
          )
          expect(IngestDspaceAssetJob).to have_received(:perform_later).with(
            hash_including(
              handle: item_handle
            )
          )
        end
      end
    end

    context "when the DSpace Item is access-restricted" do
      before do
        stub_dspace_bitstream_forbidden_requests(headers: headers, item_id: item_id)
      end

      it "sets the visibility to clients on the VPN and on campus" do
        ingester.ingest!

        expect(IngestDspaceAssetJob).not_to have_received(:perform_later).with(
          hash_including(
            source_metadata_identifier: mms_id
          )
        )
        expect(IngestDspaceAssetJob).to have_received(:perform_later).with(
          hash_including(
            handle: item_handle
          )
        )
      end
    end
  end
end
