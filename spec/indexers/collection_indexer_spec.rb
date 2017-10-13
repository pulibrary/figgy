# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CollectionIndexer do
  describe ".to_solr" do
    it "indexes collection titles into member_of_collection_titles" do
      collection = FactoryGirl.create_for_repository(:collection)
      resource = FactoryGirl.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
      output = described_class.new(resource: resource).to_solr

      expect(output["member_of_collection_titles_ssim"]).to eq [collection.title.first]
    end

    it "indexes collection titles of the ephemera boxes a folder is in" do
      collection = FactoryGirl.create_for_repository(:collection)
      folder = FactoryGirl.create_for_repository(:ephemera_folder)
      FactoryGirl.create_for_repository(:ephemera_box, member_ids: [folder.id], member_of_collection_ids: collection.id)

      output = described_class.new(resource: folder).to_solr
      expect(output["member_of_collection_titles_ssim"]).to eq [collection.title.first]
    end
  end
end
