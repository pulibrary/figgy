# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_members_ephemera_project" do
  context "when it's a project with boxes and folders" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_project, member_ids: [child.id, child_folder.id]) }
    let(:child) { FactoryGirl.create_for_repository(:ephemera_box) }
    let(:child_folder) { FactoryGirl.create_for_repository(:ephemera_folder) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Boxes'
      expect(rendered).to have_selector 'span.label-default', text: 'New'
      expect(rendered).to have_selector 'td', text: 'Box 1'
      expect(rendered).to have_selector 'td', text: '00000000000000'
      expect(rendered).to have_link 'View', href: parent_solr_document_path(parent.id, child.id)
      expect(rendered).to have_link 'Edit', href: edit_ephemera_box_path(child.id)

      expect(rendered).to have_selector 'h2', text: 'Folders'
      expect(rendered).to have_selector 'span.label-info', text: 'Needs QA'
      expect(rendered).to have_selector 'td', text: 'test folder'
      expect(rendered).to have_selector 'td', text: '12345678901234'
      expect(rendered).to have_link 'View', href: parent_solr_document_path(parent.id, child_folder.id)
      expect(rendered).to have_link 'Edit', href: edit_ephemera_folder_path(child_folder.id)
    end
  end
  context "when it's a project with templates" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_project) }
    let(:child) { FactoryGirl.create_for_repository(:template, parent_id: parent.id) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      child
      assign :document, solr_document
      render
    end
    it "shows them" do
      expect(rendered).to have_selector 'h2', text: 'Templates'
      expect(rendered).to have_content 'Test Template'
    end
  end
end
