# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_scanned_resource" do
  context "when the ScannedResource has no members" do
    let(:parent) { FactoryBot.create_for_repository(:scanned_resource, title: "Mui", rights_statement: "y") }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:change_set) { ChangeSet.for(solr_document.resource) }
    before do
      assign :document, solr_document
      assign :change_set, change_set
      render
    end

    it "allows you to attach them" do
      expect(rendered).to have_selector "input#child_scanned_resource_id_input"
      expect(rendered).to have_selector "button", text: "Attach"
      expect(rendered).to have_selector "td", text: 'This work has no volumes attached. Click "Attach Scanned Resource" or attach existing resource.'
    end
  end
end
