# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_members_scanned_map" do
  context 'when the ScannedMap has members' do
    let(:child) { FactoryBot.create_for_repository(:scanned_map, title: 'vol1', rights_statement: 'x') }
    let(:parent) { FactoryBot.create_for_repository(:scanned_map, title: 'Mui', rights_statement: 'y', member_ids: [child.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Members'
      expect(rendered).to have_selector 'td', text: 'vol1'
      expect(rendered).to have_selector 'div.label-success .text', text: 'open'
      expect(rendered).not_to have_link href: solr_document_path(child)
      expect(rendered).to have_link 'View', href: parent_solr_document_path(parent, child.id)
      expect(rendered).to have_link 'Edit', href: edit_scanned_map_path(child.id)
    end
  end
end
