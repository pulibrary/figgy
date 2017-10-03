# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_members_vector_work" do
  context 'when the VectorWork has members' do
    let(:child) { FactoryGirl.create_for_repository(:vector_work, title: 'vol1', rights_statement: 'x') }
    let(:parent) { FactoryGirl.create_for_repository(:vector_work, title: 'Mui', rights_statement: 'y', member_ids: [child.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Members'
      expect(rendered).to have_selector 'td', text: 'vol1'
      expect(rendered).to have_selector 'span.label-success', text: 'Open'
      expect(rendered).not_to have_link href: solr_document_path(child)
      expect(rendered).to have_link 'View', href: parent_solr_document_path(parent, "id-#{child.id}")
      expect(rendered).to have_link 'Edit', href: edit_vector_work_path(child.id)
    end
  end
end
