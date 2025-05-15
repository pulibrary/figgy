# frozen_string_literal: true
require "rails_helper"

describe DspaceMultivolumeIngester do
  subject(:ingester) { described_class.new(**ingester_args) }

  let(:ingester_args) do
    {
      title: title,
      handle: handle,
      collection_ids: collection_ids
    }
  end
  let(:title) { "test-title" }
  let(:collection_handle) { "88435/dsp01testcollection" }
  let(:handle) { collection_handle }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:collection_ids) { [collection.id.to_s] }
  let(:id) { ingester.id }

  let(:logger) { Logger.new(STDOUT) }

  let(:dspace_api_token) { "secret" }
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
  let(:collection_id) { collection.id.to_s }
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
  let(:oai_fixture_path) { Rails.root.join("spec", "fixtures", "dspace_ingest_oai.xml") }
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
  let(:catalog_request_url) { "https://catalog.princeton.edu/catalog.json?f%5Baccess_facet%5D%5B0%5D=Online&f%5Bpublisher%5D%5B0%5D=Alcuin%20Society&f%5Btitle%5D%5B0%5D=Alcuin%20Society%20newsletter,%20No.%2022&q=88435/dsp01test&search_field=electronic_access_1display" }
  let(:item_handle) { "88435/dsp01test" }
  let(:items_query_response) do
    [

      {
        "handle": item_handle
      }
    ].to_json
  end

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

    it "ingests items into a new multi-volume ScannedResource" do
      ingester.ingest!(member_of_collection_ids: collection_ids)
      expect(IngestDspaceAssetJob).to have_received(:perform_later).with(
        hash_including(
          dspace_api_token: nil,
          ingest_service_klass: DspaceIngester,
          member_of_collection_ids: collection_ids
        )
      )
    end

    context "when resources have been persisted with the same ARK identifiers" do
      let(:ingester_args) do
        {
          title: title,
          handle: handle,
          collection_ids: collection_ids
        }
      end
      let(:identifier) do
        [
          "http://arks.princeton.edu/ark:/#{handle}"
        ]
      end
      let(:existing) do
        FactoryBot.create_for_repository(:scanned_resource, identifier: identifier)
      end
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      before do
        existing
      end

      context "when the ingester service is told to delete preexisting resources" do
        let(:ingester_args) do
          {
            title: title,
            handle: handle,
            collection_ids: collection_ids,
            delete_preexisting: true
          }
        end

        it "deletes existing resources with matching ARK URLs" do
          ingester.ingest!(member_of_collection_ids: collection_ids)
          expect(IngestDspaceAssetJob).to have_received(:perform_later).with(
            hash_including(
              delete_preexisting: true
            )
          )

          expect do
            metadata_adapter.query_service.find_by(id: existing.id)
          end.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        end
      end

      it "by default does not ingest a new resource with an identical ARK" do
        expect(existing).to be_persisted
        ingester.ingest!(member_of_collection_ids: collection_ids)
        expect(IngestDspaceAssetJob).to have_received(:perform_later).with(
          hash_including(
            parent_id: existing.id.to_s
          )
        )
        expect(existing).to be_persisted
      end
    end
  end
end
