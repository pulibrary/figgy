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
  end
end
