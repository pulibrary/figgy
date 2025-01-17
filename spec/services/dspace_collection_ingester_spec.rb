# frozen_string_literal: true
require "rails_helper"

RSpec.describe DspaceCollectionIngester do
  subject(:ingester) { described_class.new(handle: handle, collection_ids: collection_ids) }
  let(:collection_handle) { "88435/dsp01testcollection" }
  let(:handle) { collection_handle }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:collection_ids) { [collection.id] }

  let(:logger) { Logger.new(STDOUT) }
  let(:dspace_api_token) { "secret" }
  let(:id) { ingester.id }
  let(:request_authz_headers) do
    {
      "Rest-Dspace-Token" => "secret"
    }
  end
  let(:headers) do
    {
      "Accept:": "application/json"
    }
  end
  let(:collection_id) { "test-collection-id" }
  let(:collection_response_body) do
    {
      "id": collection_id,
      "type": "collection"
    }.to_json
  end

  let(:item_id) { "test-id" }
  let(:response_body) do
    {
      "id": item_id,
      "type": "item"
    }.to_json
  end
  let(:authz_bitstream_response) do
    [
      {
        "name" => "test-name",
        "sequenceId" => "test-sequence-id"
      }
    ]
  end
  let(:bitstream_response) { authz_bitstream_response }
  let(:xml_headers) do
    {
      "Accept:": "application/xml"
    }
  end
  let(:oai_document_fixture_file) { Rails.root.join("spec", "fixtures", "dspace_ingest_oai.xml") }
  let(:oai_document_fixture) { File.read(oai_document_fixture_file) }
  let(:oai_document) do
    Nokogiri::XML(oai_document_fixture)
  end
  let(:oai_response) do
    oai_document.to_xml
  end
  let(:mms_id) { "99125128447906421" }
  let(:catalog_response_meta) do
    {
      "pages" => {
        "total_count" => 1
      }
    }
  end

  let(:successful_catalog_response) do
    {
      "meta" => catalog_response_meta,
      "data" => [
        {
          "id" => mms_id,
          "attributes" => {
            "electronic_portfolio_s" => nil
          }
        }
      ]
    }
  end
  let(:catalog_response) { successful_catalog_response }
  let(:catalog_response_url) { "https://catalog.princeton.edu/catalog.json?f%5Baccess_facet%5D%5B0%5D=Online&f%5Bpublisher%5D%5B0%5D=Alcuin%20Society&f%5Btitle%5D%5B0%5D=Alcuin%20Society%20newsletter,%20No.%2022&q=88435/dsp01test&search_field=electronic_access_1display" }
  let(:item_handle) { "88435/dsp01test" }
  let(:items_query_response) do
    [

      {
        "handle": item_handle
      }
    ].to_json
  end

  before do
    items_query = "https://dataspace.princeton.edu/rest/collections/#{collection_id}/items"
    stub_request(:get, items_query).with(
      headers: {
        "Accept": "application/json"
      },
      query: {
        "limit": 20,
        "offset": 0
      }
    ).to_return(
      status: 200,
      body: items_query_response
    )

    stub_request(:get,
                   "https://dataspace.princeton.edu/rest/handle/#{handle}").to_return(
                    status: 200,
                    headers: headers,
                    body: collection_response_body
                  )
  end

  describe "#ingest!" do
    before do
      allow(IngestFolderJob).to receive(:perform_later)

      stub_catalog(bib_id: mms_id)
      stub_request(:get,
                   "https://dataspace.princeton.edu/rest/handle/#{item_handle}").to_return(
                    status: 200,
                    headers: headers,
                    body: response_body
                  )

      stub_request(:get,
                   "https://dataspace.princeton.edu/oai/request?identifier=oai:dataspace.princeton.edu:#{item_handle}&metadataPrefix=oai_dc&verb=GetRecord").to_return(
                   status: 200,
                   headers: headers,
                   body: oai_response
                 )
      stub_request(:get,
                   catalog_response_url).to_return(
                   status: 200,
                   headers: headers,
                   body: catalog_response.to_json
                 )
    end

    context "when authenticated with an API token" do
      before do
        stub_request(:get,
                    "https://dataspace.princeton.edu/rest/items/#{item_id}/bitstreams?limit=20&offset=0").to_return(
                    status: 200,
                    headers: headers,
                    body: bitstream_response.to_json
                  )
      end

      it "enqueues a new resource for ingestion" do
        ingester.ingest!

        expect(IngestFolderJob).to have_received(:perform_later)
      end

      context "when providing default resource attributes" do
        it "enqueues a new resource for ingestion with the attributes" do
          ingester.ingest!(member_of_collection_ids: collection_ids)

          expect(IngestFolderJob).to have_received(:perform_later).with(hash_including(member_of_collection_ids: collection_ids))
        end
      end

      context "when the MMS ID cannot be found using the ARK, " do
        let(:catalog_response) do
          {
            "meta" => catalog_response_meta,
            "data" => []
          }
        end

        before do
          # stub_request(:get, "https://catalog.princeton.edu/catalog.json?q=Alcuin%20Society&search_field=all_fields").to_return(
          #  status: 200,
          #  headers: headers,
          #  body: catalog_response.to_json
          # )
          # stub_request(:get, "https://catalog.princeton.edu/catalog.json?q=Alcuin%20Society%20newsletter,%20No.%2022&search_field=all_fields").to_return(
          #  status: 200,
          #  headers: headers,
          #  body: catalog_response.to_json
          # )
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester.ingest!

          expect(IngestFolderJob).not_to have_received(:perform_later).with(source_metadata_identifier: mms_id)
          expect(IngestFolderJob).to have_received(:perform_later)
        end
      end

      context "when a bib. record can be found using the title instead of the ARK" do
        let(:catalog_response_by_ark) do
          {
            "meta" => catalog_response_meta,
            "data" => []
          }
        end
        let(:catalog_response) { catalog_response_by_ark }
        let(:catalog_response_by_title) { successful_catalog_response }

        before do
          # stub_request(:get, "https://catalog.princeton.edu/catalog.json?q=Alcuin%20Society&search_field=all_fields").to_return(
          #  status: 200,
          #  headers: headers,
          #  body: catalog_response_by_title.to_json
          # )
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester.ingest!

          expect(IngestFolderJob).not_to have_received(:perform_later).with(source_metadata_identifier: mms_id)
          expect(IngestFolderJob).to have_received(:perform_later)
        end
      end

      context "when a bib. record can be found using the ARK but it does not have the `electronic_portfolio_s` attribute" do
        let(:catalog_response) do
          {
            "meta" => catalog_response_meta,
            "data" => [
              {
                "id" => mms_id,
                "attributes" => {}
              }
            ]
          }
        end

        before do
          # stub_request(:get, "https://catalog.princeton.edu/catalog.json?q=Alcuin%20Society&search_field=all_fields").to_return(
          #  status: 200,
          #  headers: headers,
          #  body: catalog_response.to_json
          # )

          # stub_request(:get, "https://catalog.princeton.edu/catalog.json?q=Alcuin%20Society%20newsletter,%20No.%2022&search_field=all_fields").to_return(
          #  status: 200,
          #  headers: headers,
          #  body: catalog_response.to_json
          # )
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester.ingest!

          expect(IngestFolderJob).not_to have_received(:perform_later).with(source_metadata_identifier: mms_id)
          expect(IngestFolderJob).to have_received(:perform_later)
        end
      end
    end

    context "when the DSpace Item is access-restricted" do
      let(:empty_bitstream_response) do
        []
      end

      before do
        stub_request(:get,
                    "https://dataspace.princeton.edu/rest/items/#{item_id}/bitstreams?limit=20&offset=0").to_return(
                    status: 200,
                    headers: headers,
                    body: bitstream_response.to_json
                  ).to_return(
                    status: 200,
                    headers: headers,
                    body: empty_bitstream_response.to_json
                  )
      end

      it "sets the visibility to clients on the VPN and on campus" do
        ingester.ingest!
      end
    end
  end

  describe "#id" do
    xit "retrieves the ID from the API response" do
      expect(ingester.id).to eq(id)
    end
  end
end
