# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_collection.html.erb" do
  context "when it's a collection with members" do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:scanned_resource1) do
      FactoryBot.create_for_repository(
        :scanned_resource,
        title: ["First Member"],
        member_of_collection_ids: [collection.id]
      )
    end
    let(:scanned_resource2) do
      FactoryBot.create_for_repository(
        :scanned_resource,
        title: ["Second Member"],
        member_of_collection_ids: [collection.id]
      )
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: collection) }
    let(:solr_document) { SolrDocument.new(document) }

    before do
      assign :document, solr_document
      render
    end

    it "links to member resources" do
      expect(rendered).to have_link "View Members List"
    end
  end
end
