# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_ephemera_project" do
  context "when it's a project with boxes and folders" do
    let(:parent) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [child.id, child_folder.id]) }
    let(:child) { FactoryBot.create_for_repository(:ephemera_box, drive_barcode: "11111111111110") }
    let(:child_folder) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it "shows them" do
      expect(rendered).to have_selector "h2", text: "Boxes"
      expect(rendered).to have_selector "span.badge-dark", text: "New"
      expect(rendered).to have_selector "td", text: "1"
      expect(rendered).to have_selector "td", text: "00000000000000"
      expect(rendered).to have_selector "td", text: "11111111111110"
      expect(rendered).to have_link "View", href: solr_document_path(child.id)
      expect(rendered).to have_link "Edit", href: edit_ephemera_box_path(child.id)

      expect(rendered).to have_selector "h2", text: "Folders"
    end
  end
  context "when it's a project with boxes that have been deleted" do
    it "renders the project" do
      change_set_persister = ChangeSetPersister.default
      child = FactoryBot.create_for_repository(:ephemera_box, state: "complete")
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [child.id])
      change_set_persister.persister.save(resource: child)
      change_set_persister.persister.save(resource: project)
      change_set_persister.delete(change_set: ChangeSet.for(child))
      document = SolrDocument.new(Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: project))

      assign :document, document
      render
    end
  end
  context "when it's a project with templates" do
    let(:parent) { FactoryBot.create_for_repository(:ephemera_project) }
    let(:child) { FactoryBot.create_for_repository(:template, parent_id: parent.id) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      child
      assign :document, solr_document
      render
    end
    it "shows them" do
      expect(rendered).to have_selector "h2", text: "Templates"
      expect(rendered).to have_content "Test Template"
    end
  end
end
