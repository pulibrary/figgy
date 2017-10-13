# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_members_ephemera_project" do
  context "when it's a project with boxes" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_project, member_ids: [child.id]) }
    let(:child) { FactoryGirl.create_for_repository(:ephemera_box) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Boxes'
      expect(rendered).to have_link 'Box 1', href: solr_document_path(id: child.id)
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
