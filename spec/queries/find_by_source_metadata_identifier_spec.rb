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
end
