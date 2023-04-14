# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_multi_volume_work" do
  context "when the ScannedResource has members" do
    let(:file_set1) { FactoryBot.create_for_repository(:file_set, file_metadata: { use: Valkyrie::Vocab::PCDMUse.OriginalFile, fixity_success: 1 }) }
    let(:file_set2) { FactoryBot.create_for_repository(:file_set, file_metadata: { use: Valkyrie::Vocab::PCDMUse.OriginalFile, fixity_success: 0 }) }
    let(:original_file) { instance_double FileMetadata }
    let(:child) { FactoryBot.create_for_repository(:scanned_resource, title: "vol1", rights_statement: "x", member_ids: [file_set1.id, file_set2.id]) }
    let(:parent) { FactoryBot.create_for_repository(:scanned_resource, title: "Mui", rights_statement: "y", member_ids: [child.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:change_set) { ChangeSet.for(solr_document.resource) }
    before do
      assign :document, solr_document
      assign :change_set, change_set
      render
    end

    it "shows them" do
      expect(rendered).to have_selector "div", text: "Members"
      expect(rendered).to have_selector "td", text: "vol1"
      expect(rendered).to have_selector "div.badge-success .text", text: "open"
      expect(rendered).not_to have_link href: solr_document_path(child)
      expect(rendered).to have_link "View", href: parent_solr_document_path(parent, child.id)
      expect(rendered).to have_link "Edit", href: edit_scanned_resource_path(child.id)
      expect(rendered).to have_selector "button", text: "Detach"
      expect(rendered).to have_selector "input#child_scanned_resource_id_input"
      expect(rendered).to have_selector "button", text: "Attach"
    end
  end
end
