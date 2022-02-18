# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe SortingIndexer do
  it_behaves_like "a Valkyrie::Persistence::Solr::Indexer"
  describe "#to_solr" do
    context "when given a resource with a sort title" do
      it "indexes it" do
        resource = instance_double(ScannedResource, sort_title: "Sort")
        indexer = described_class.new(resource: resource)

        expect(indexer.to_solr).to eq(title_ssort: "Sort")
      end
    end
    context "when given a resource with a title" do
      it "indexes the first title downcased" do
        resource = instance_double(ScannedResource, title: ["Sort"])
        indexer = described_class.new(resource: resource)

        expect(indexer.to_solr).to eq(title_ssort: "sort")
      end
    end
    context "when there's no titles" do
      it "defaults to the id of the resource" do
        resource = instance_double(ScannedResource, id: Valkyrie::ID.new("sort"))
        indexer = described_class.new(resource: resource)

        expect(indexer.to_solr).to eq(title_ssort: "sort")
      end
    end
  end
end
