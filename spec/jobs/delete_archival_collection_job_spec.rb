# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeleteArchivalCollectionJob do
  with_queue_adapter :inline
  context "when there are objects to remove" do
    it "removes all of the objects" do
      bib = "WC055_c0001"
      FactoryBot.create_for_repository(:scanned_resource, archival_collection_code: bib)
      qs = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      resources = qs.custom_queries.find_by_property(property: :archival_collection_code, value: bib)

      expect(resources.count).not_to eq(0)
      described_class.perform_now(id: bib)
      resources = qs.custom_queries.find_by_property(property: :archival_collection_code, value: bib)
      expect(resources.count).to eq(0)
    end
  end

  describe ".perform" do
    it "does not error when the collection does not exist" do
      expect { described_class.perform_now(id: :nonexistent) }.not_to raise_error
    end
  end
end
