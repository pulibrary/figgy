# frozen_string_literal: true
require "rails_helper"

RSpec.describe DspaceIngester do
  subject(:dspace_ingester) { described_class.new(handle: handle) }
  let(:item_handle) { "88435/dsp01test" }
  let(:handle) { item_handle }
  let(:ark) { "http://arks.princeton.edu/ark:/#{handle}" }

  let(:logger) { Logger.new(STDOUT) }
  let(:dspace_api_token) { "secret" }
  let(:item_id) { "test-id" }
  let(:id) { item_id }
  let(:oai_fixture_path) { Rails.root.join("spec", "fixtures", "dspace_ingest_oai.xml") }
  let(:headers) do
    {
      "Accept:": "application/json"
    }
  end
  let(:mms_id) { "99125128447906421" }
  let(:catalog_request_url) { "https://catalog.princeton.edu/catalog.json?f%5Baccess_facet%5D%5B0%5D=Online&f%5Bpublisher%5D%5B0%5D=Alcuin%20Society&f%5Btitle%5D%5B0%5D=Alcuin%20Society%20newsletter,%20No.%2022&q=88435/dsp01test&search_field=electronic_access_1display" }

  before do
    stub_dspace_item_requests(headers: headers, item_id: item_id, item_handle: item_handle)
  end

  describe "#ingest!" do
    let(:catalog_request_url) do
      "https://catalog.princeton.edu/catalog.json?f%5Baccess_facet%5D%5B0%5D=Online&f%5Bpublisher%5D%5B0%5D=Alcuin%20Society&f%5Btitle%5D%5B0%5D=Alcuin%20Society%20newsletter,%20No.%2022&q=88435/dsp01test&search_field=electronic_access_1display"
    end

    let(:persisted_resource) { FactoryBot.create(:scanned_resource, identifier: ark) }

    before do
      persisted_resource
      allow(IngestFolderJob).to receive(:perform_now).and_return(persisted_resource)

      stub_catalog(bib_id: mms_id)
      stub_dspace_item_requests(headers: headers, item_id: item_id, item_handle: item_handle)
      stub_dspace_catalog_requests(headers: headers, mms_id: mms_id, catalog_request_url: catalog_request_url)
      stub_dspace_oai_requests(headers: headers, item_handle: item_handle, oai_fixture_path: oai_fixture_path)
    end

    context "when authenticated with an API token" do
      let(:headers) do
        {
          "Rest-Dspace-Token" => "secret",
          "Accept" => "application/json"
        }
      end

      let(:status) { instance_double(Process::Status) }

      before do
        stub_dspace_visibility_request(headers: headers, item_id: id)
        stub_dspace_bitstream_requests(headers: headers, item_id: id)

        allow(status).to receive(:exitstatus).and_return(0)
        allow(Open3).to receive(:capture2e).and_return(["", status])
      end

      it "enqueues a new resource for ingestion" do
        ingester = described_class.new(handle: handle, logger: logger, dspace_api_token: dspace_api_token)
        ingester.ingest!

        expect(IngestFolderJob).to have_received(:perform_now)
      end

      context "when providing default resource attributes" do
        it "enqueues a new resource for ingestion with the attributes" do
          collections = [123]
          ingester = described_class.new(handle: handle, logger: logger, dspace_api_token: dspace_api_token)
          ingester.ingest!(member_of_collection_ids: collections)

          expect(IngestFolderJob).to have_received(:perform_now).with(hash_including(member_of_collection_ids: collections))
        end
      end

      context "when the MMS ID cannot be found using the ARK, " do
        before do
          stub_dspace_bitstream_requests(headers: headers, item_id: item_id)
          stub_dspace_catalog_missing_requests(headers: headers, catalog_request_url: catalog_request_url)
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester = described_class.new(handle: handle, logger: logger, dspace_api_token: dspace_api_token)
          ingester.ingest!

          expect(IngestFolderJob).not_to have_received(:perform_now).with(
            hash_including(
              source_metadata_identifier: mms_id
            )
          )
          expect(IngestFolderJob).to have_received(:perform_now).with(
            hash_including(
              creator: "Greaves, Howard",
              date: "2015",
              directory: "/tmp/test-id",
              identifier: "http://arks.princeton.edu/ark:/88435/dsp01gb19f818g",
              language: "en",
              publisher: "Alcuin Society",
              relation: "Alcuin Society newsletter, 2015, No. 22",
              subject: "Book collecting",
              title: "Alcuin Society newsletter, No. 22",
              visibility: "open"
            )
          )
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
          stub_dspace_bitstream_requests(headers: headers, item_id: item_id)
          stub_dspace_catalog_missing_requests(headers: headers, catalog_request_url: catalog_request_url)
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester = described_class.new(handle: handle, logger: logger, dspace_api_token: dspace_api_token)
          ingester.ingest!

          expect(IngestFolderJob).not_to have_received(:perform_now).with(
            hash_including(
              source_metadata_identifier: mms_id
            )
          )
          expect(IngestFolderJob).to have_received(:perform_now).with(
            hash_including(
              creator: "Greaves, Howard",
              date: "2015",
              directory: "/tmp/test-id",
              identifier: "http://arks.princeton.edu/ark:/88435/dsp01gb19f818g",
              language: "en",
              publisher: "Alcuin Society",
              relation: "Alcuin Society newsletter, 2015, No. 22",
              subject: "Book collecting",
              title: "Alcuin Society newsletter, No. 22",
              visibility: "open"
            )
          )
        end
      end

      context "when a bib. record can be found using the ARK but it does not have the `electronic_portfolio_s` attribute" do
        before do
          stub_dspace_invalid_catalog_requests(headers: headers, catalog_request_url: catalog_request_url, mms_id: mms_id)
        end

        it "logs a warning and enqueues a new resource for ingestion without the MMS ID" do
          ingester = described_class.new(handle: handle, logger: logger, dspace_api_token: dspace_api_token)
          ingester.ingest!

          expect(IngestFolderJob).not_to have_received(:perform_now).with(source_metadata_identifier: mms_id)
          expect(IngestFolderJob).to have_received(:perform_now)
        end
      end
    end

    context "when the DSpace Item is access-restricted" do
      before do
        stub_dspace_access_restricted_request(headers: headers, item_id: item_id)
        stub_dspace_bitstream_requests(headers: headers, item_id: item_id)
      end

      it "ingests the item with restricted visibility" do
        ingester = described_class.new(handle: handle, logger: logger, dspace_api_token: dspace_api_token)

        ingester.ingest!

        expect(IngestFolderJob).to have_received(:perform_now).with(
          hash_including(
            creator: "Greaves, Howard",
            date: "2015",
            directory: "/tmp/test-id",
            identifier: "http://arks.princeton.edu/ark:/88435/dsp01gb19f818g",
            language: "en",
            publisher: "Alcuin Society",
            relation: "Alcuin Society newsletter, 2015, No. 22",
            subject: "Book collecting",
            title: "Alcuin Society newsletter, No. 22",
            visibility: "on_campus"
          )
        )
      end
    end

    context "when resources with the same ARK have been persisted" do
      let(:identifier) do
        [
          # "http://arks.princeton.edu/ark:/#{handle}"
          "http://arks.princeton.edu/ark:/88435/dsp01gb19f818g"
        ]
      end
      let(:existing) do
        FactoryBot.create_for_repository(:scanned_resource, identifier: identifier)
      end
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      before do
        existing
        stub_dspace_visibility_request(headers: headers, item_id: item_id)
        stub_dspace_bitstream_requests(headers: headers, item_id: item_id)
      end

      context "when the ingester service is told to delete preexisting resources" do
        it "deletes the persisted resources" do
          expect(existing).to be_persisted

          ingester = described_class.new(
            handle: handle, logger: logger, dspace_api_token: dspace_api_token,
            delete_preexisting: true
          )

          ingester.ingest!
          expect do
            metadata_adapter.query_service.find_by(id: existing.id)
          end.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        end
      end
    end

    context "when a parent ID is provided" do
      let(:parent) do
        FactoryBot.create_for_repository(:scanned_resource)
      end

      before do
        allow(AddMemberJob).to receive(:perform_later)
        stub_dspace_visibility_request(headers: headers, item_id: item_id)
        stub_dspace_bitstream_requests(headers: headers, item_id: item_id)
      end

      it "enqueues a job to add the resource to the parent" do
        ingester = described_class.new(
          handle: handle,
          logger: logger,
          dspace_api_token: dspace_api_token
        )

        ingester.ingest!(
          parent_id: parent.id.to_s
        )

        expect(AddMemberJob).to have_received(:perform_later).with(hash_including(parent_id: parent.id.to_s))
      end
    end
  end
end
