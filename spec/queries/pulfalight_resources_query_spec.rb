require "rails_helper"

describe PulfalightResourcesQuery do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  describe "#pulfalight_resources" do
    it "finds only the resources in the collection" do
      stub_findingaid(pulfa_id: "C0652_c0383")
      stub_findingaid(pulfa_id: "AC044_c0003")
      collection_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "C0652_c0383", archival_collection_code: "C0652")
      _other_collection = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "AC044_c0003", archival_collection_code: "AC044")

      expect(query.pulfalight_resources(collection: "C0652").map(&:id).to_a).to eq [collection_resource.id]
    end
  end
end
