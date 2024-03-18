# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindBySourceMetadataIdentifier do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_source_metadata_identifier" do
    it "can find objects by their identifier" do
      stub_catalog(bib_id: "991234563506421")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["991234563506421"])
      expect(query_service.custom_queries.find_by_source_metadata_identifier(source_metadata_identifier: "991234563506421")).to eq [resource]
    end

    it "will find the old ID if given an alma ID" do
      # since the shorter bibid is no longer valid, we have to create the object
      # with the longer bibid and then force the short id back in.
      stub_catalog(bib_id: "991234563506421")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["991234563506421"])
      resource.source_metadata_identifier = ["991234563506421"]
      ChangeSetPersister.default.metadata_adapter.persister.save(resource: resource)
      expect(query_service.custom_queries.find_by_source_metadata_identifier(source_metadata_identifier: "991234563506421").map(&:id)).to eq [resource.id]
    end
  end

  describe "#find_by_source_metadata_identifiers" do
    it "can find alma and non-alma objects by source identifier" do
      stub_catalog(bib_id: "991234563506421")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["991234563506421"])
      # since the shorter bibid is no longer valid, we have to create the object
      # with the longer bibid and then force the short id back in.
      stub_catalog(bib_id: "9985434293506421")
      resource2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["9985434293506421"])
      resource2.source_metadata_identifier = ["8543429"]
      ChangeSetPersister.default.metadata_adapter.persister.save(resource: resource2)
      expect(query_service.custom_queries.find_by_source_metadata_identifiers(source_metadata_identifiers: ["991234563506421", "9985434293506421"]).map(&:id)).to eq [resource, resource2].map(&:id)
    end
  end
end
