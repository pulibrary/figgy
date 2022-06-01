# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_issue" do
  context "when the Numismatics::Issue has Numismatics::Coin members" do
    let(:child) { FactoryBot.create_for_repository(:coin) }
    let(:parent) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [child.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:change_set) { ChangeSet.for(solr_document.resource) }
    before do
      assign :document, solr_document
      assign :resource, solr_document.resource
      assign :change_set, change_set
      render
    end

    it "shows them" do
      expect(rendered).to have_selector "td", text: child.title.first
      expect(rendered).to have_selector "div.badge-success .text", text: "open"
      expect(rendered).not_to have_link href: solr_document_path(child)
      expect(rendered).to have_link "View", href: parent_solr_document_path(parent, child.id)
      expect(rendered).to have_link "Edit", href: edit_numismatics_coin_path(child.id)
    end
  end

  context "when the Numismatics::Issue has no members" do
    let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: issue) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:change_set) { ChangeSet.for(solr_document.resource) }
    before do
      assign :document, solr_document
      assign :resource, solr_document.resource
      assign :change_set, change_set
      render
    end

    it "prompts user to attach one" do
      expect(rendered).to have_selector "td", text: "This work has no coins attached. Click the \"Attach Coin\" button to create a new coin."
    end
  end
end
