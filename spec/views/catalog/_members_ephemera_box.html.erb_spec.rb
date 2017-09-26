# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_members_ephemera_box" do
  context "when it's a box with folders" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_box, member_ids: [child.id]) }
    let(:child) { FactoryGirl.create_for_repository(:ephemera_folder) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Folders'
      expect(rendered).to have_selector 'td.folder_number', text: "one"
      expect(rendered).to have_link "one", href: "/catalog/parent/#{parent.id}/id-#{child.id}"
      expect(rendered).not_to have_selector 'td.folder_number', text: "[\"one\"]"
      expect(rendered).to have_selector 'td.barcode', text: child.barcode.first
      expect(rendered).not_to have_selector 'td.barcode', text: "[\"#{child.barcode.first}\"]"
      expect(rendered).to have_selector 'td.genre', text: child.genre.first
      expect(rendered).not_to have_selector 'td.genre', text: "[\"#{child.genre.first}\"]"
    end
  end
end
