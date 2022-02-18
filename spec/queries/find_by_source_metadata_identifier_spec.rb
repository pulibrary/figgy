# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindBySourceMetadataIdentifier do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_source_metadata_identifier" do
    it "can find objects by their identifier" do
      stub_bibdata(bib_id: "123456")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["123456"])
      expect(query_service.custom_queries.find_by_source_metadata_identifier(source_metadata_identifier: "123456")).to eq [resource]
    end
    it "will find the old ID if given an alma ID" do
      stub_bibdata(bib_id: "123456")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["123456"])
      expect(query_service.custom_queries.find_by_source_metadata_identifier(source_metadata_identifier: "991234563506421")).to eq [resource]
    end
  end

  describe "#find_by_source_metadata_identifiers" do
    it "can find alma and non-alma objects by source identifier" do
      stub_bibdata(bib_id: "991234563506421")
      stub_bibdata(bib_id: "8543429")
      resource2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["8543429"])
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["991234563506421"])
      expect(query_service.custom_queries.find_by_source_metadata_identifiers(source_metadata_identifiers: ["991234563506421", "9985434293506421"])).to eq [resource, resource2]
    end
  end
end
