# frozen_string_literal: true
require 'rails_helper'

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

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Folders'
      expect(rendered).to have_selector 'th', text: 'Folder Number'
      expect(rendered).to have_selector 'td.folder_number', text: "one"
      expect(rendered).to have_link "one", href: "/catalog/parent/#{parent.id}/#{child.id}"
      expect(rendered).not_to have_selector 'td.folder_number', text: "[\"one\"]"
      expect(rendered).to have_selector 'td.barcode', text: child.barcode.first
      expect(rendered).not_to have_selector 'td.barcode', text: "[\"#{child.barcode.first}\"]"
      expect(rendered).to have_selector 'td.genre', text: child.genre.first
      expect(rendered).not_to have_selector 'td.genre', text: "[\"#{child.genre.first}\"]"
      expect(rendered).to have_link "View", href: "/catalog/parent/#{parent.id}/#{child.id}"
      expect(rendered).to have_link "Edit", href: "/concern/ephemera_folders/#{child.id}/edit"
      expect(rendered).not_to have_link "Delete", href: "/concern/ephemera_folders/#{child.id}"
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

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Folders'
      expect(rendered).not_to have_selector 'th', text: 'Folder Number'
      expect(rendered).to have_selector 'td', text: 'test folder'
      expect(rendered).to have_link "View", href: "/catalog/parent/#{parent.id}/#{child.id}"
      expect(rendered).to have_link "Edit", href: "/concern/ephemera_folders/#{child.id}/edit"
      expect(rendered).not_to have_link "Delete", href: "/concern/ephemera_folders/#{child.id}"
    end
  end
end
