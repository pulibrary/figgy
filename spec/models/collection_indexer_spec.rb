# frozen_string_literal: true
require "rails_helper"

RSpec.describe CollectionIndexer do
  describe ".to_solr" do
    it "indexes collection titles into member_of_collection_titles" do
      collection = FactoryBot.create_for_repository(:collection)
      resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
      output = described_class.new(resource: resource).to_solr

      expect(output["member_of_collection_titles_ssim"]).to eq [collection.title.first]
      expect(output["member_of_collection_titles_tesim"]).to eq [collection.title.first]
    end

    context "with a deletion marker" do
      it "indexes collection titles into member_of_collection_titles" do
        collection = FactoryBot.create_for_repository(:collection)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
        persister = ChangeSetPersister.default
        persister.delete(change_set: ChangeSet.for(resource))
        deletion_marker = persister.query_service.find_all_of_model(model: DeletionMarker).first
        output = described_class.new(resource: deletion_marker).to_solr

        expect(output["member_of_collection_titles_ssim"]).to eq [collection.title.first]
        expect(output["member_of_collection_titles_tesim"]).to eq [collection.title.first]
      end
    end
  end
end
