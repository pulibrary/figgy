# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_members_collection.html.erb" do
  context "when it's a collection with members" do
    let(:collection) { FactoryGirl.create_for_repository(:collection) }
    let(:scanned_resource1) do
      FactoryGirl.create_for_repository(
        :scanned_resource,
        title: ['First Member'],
        member_of_collection_ids: [collection.id]
      )
    end
    let(:scanned_resource2) do
      FactoryGirl.create_for_repository(
        :scanned_resource,
        title: ['Second Member'],
        member_of_collection_ids: [collection.id]
      )
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: collection) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:response) do
      instance_double(Blacklight::Solr::Response,
                      empty?: false,
                      start: 0,
                      grouped?: false)
    end
    let(:document_facade) { instance_double(SolrFacadeService::SolrFacade, total_pages: 1, members: member_documents) }
    let(:member_documents) do
      [
        SolrDocument.new(Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource1)),
        SolrDocument.new(Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource2))
      ]
    end

    before do
      stub_blacklight_views
      allow(controller).to receive(:render_bookmarks_control?).and_return(false)
      assign :document, solr_document
      assign :document_facade, document_facade
      assign :response, response
      render
    end

    it 'shows all member resources' do
      expect(rendered).to have_selector 'h2', text: 'Members'
      expect(rendered).to have_link "First Member", href: "/catalog/#{scanned_resource1.id}"
      expect(rendered).to have_link "Second Member", href: "/catalog/#{scanned_resource2.id}"
    end
  end
end
