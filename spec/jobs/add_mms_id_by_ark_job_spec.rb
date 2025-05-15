# frozen_string_literal: true

require "rails_helper"

describe AddMmsIdByArkJob do
  subject(:job) { described_class.new }

  let(:handle) { "88435/3n203z10v" }
  let(:identifier) do
    [
      "http://arks.princeton.edu/ark:/#{handle}"
    ]
  end
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, identifier: identifier) }
  let(:mms_id) { "9985434293506421" }
  let(:response_body) do
    {
      "data": [
        {
          "id": mms_id,
          "attributes": {
            "electronic_access_1display": {
              "attributes": {
                "value": [
                  handle
                ]
              }
            }
          }
        }
      ]
    }
  end

  describe "#perform" do
    let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

    before do
      stub_catalog(bib_id: mms_id)
      stub_request(:get, "https://catalog.princeton.edu/catalog.json?q=#{handle}&search_field=electronic_access_1display").to_return(
        headers: {},
        status: 200,
        body: response_body.to_json
      )

      resource
    end

    it "queries the catalog the MMS ID using the title of the resource" do
      described_class.perform_now(resource_id: resource.id.to_s)
      persisted = metadata_adapter.query_service.find_by(id: resource.id)

      expect(persisted.source_metadata_identifier).to eq([mms_id])
    end

    context "when the search results from the catalog are empty" do
      let(:response_body) do
        {
          "data": []
        }
      end

      before do
        allow(AddMmsIdByTitleJob).to receive(:perform_later)
      end

      it "does not update the source_metadata_identifier and enqueues a job to search for the MMS ID by title" do
        described_class.perform_now(resource_id: resource.id.to_s)

        expect(AddMmsIdByTitleJob).to have_received(:perform_later).with(resource_id: resource.id.to_s)
        persisted = metadata_adapter.query_service.find_by(id: resource.id)

        expect(persisted.source_metadata_identifier).to be nil
      end
    end
  end
end
