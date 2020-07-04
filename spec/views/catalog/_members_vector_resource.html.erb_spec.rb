# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_vector_resource" do
  context "when the VectorResource has members" do
    let(:child) { FactoryBot.create_for_repository(:vector_resource, title: "child vector", rights_statement: "x") }
    let(:parent) { FactoryBot.create_for_repository(:vector_resource, title: "parent vector", rights_statement: "y", member_ids: [child.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:change_set) { ChangeSet.for(solr_document.resource) }
    before do
      assign :document, solr_document
      assign :resource, solr_document.resource
      assign :change_set, change_set
      assign :unattached_vector_resources, []
      assign :unrelated_parent_raster_resources, []
      render
    end

    it "shows them" do
      expect(rendered).to have_selector "td", text: "child vector"
      expect(rendered).to have_selector "div.label-success .text", text: "open"
      expect(rendered).not_to have_link href: solr_document_path(child)
      expect(rendered).to have_link "View", href: parent_solr_document_path(parent, child.id)
      expect(rendered).to have_link "Edit", href: edit_vector_resource_path(child.id)
    end
  end
end
