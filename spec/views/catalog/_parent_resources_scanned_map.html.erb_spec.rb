# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_parent_resources_scanned_map" do
  context "when a ScannedMap has a parent" do
    let(:child) { FactoryBot.create_for_repository(:scanned_map, title: "child map", rights_statement: "x") }
    let(:parent) { FactoryBot.create_for_repository(:scanned_map, title: "parent map", rights_statement: "y", member_ids: [child.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: child) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:change_set) { ChangeSet.for(solr_document.resource) }
    before do
      parent
      assign :document, solr_document
      assign :resource, solr_document.resource
      assign :change_set, change_set
      render
    end

    it "shows the parent" do
      expect(rendered).to have_link "View", href: solr_document_path(parent.id)
      expect(rendered).to have_link "Edit", href: edit_scanned_map_path(parent.id)
    end
  end
end
