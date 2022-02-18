# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_members_ephemera_box" do
  context "when it's a box with folders" do
    let(:parent) { FactoryBot.create_for_repository(:ephemera_box, member_ids: [child.id]) }
    let(:child) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it "shows them" do
      expect(rendered).to have_selector "h2", text: "Folders"
      expect(rendered).to have_selector "th", text: "Folder Number"
      expect(rendered).to have_selector "table.datatable[data-ajax='/concern/ephemera_boxes/#{parent.id}/folders']"
    end
  end
  context "when it's a project with folders" do
    let(:parent) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [child.id]) }
    let(:child) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it "shows them" do
      expect(rendered).to have_selector "h2", text: "Folders"
      expect(rendered).not_to have_selector "th", text: "Folder Number"
      expect(rendered).to have_selector "table.datatable[data-ajax='/concern/ephemera_projects/#{parent.id}/folders']"
    end
  end
end
