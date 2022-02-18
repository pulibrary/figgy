# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_members_playlist" do
  let(:playlist) { FactoryBot.create_for_repository(:playlist) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: playlist) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:user) }

  before do
    assign :document, solr_document
    sign_in user
    render
  end

  context "as an admin" do
    let(:user) { FactoryBot.create(:admin) }
    it "has a tag for the document adder" do
      expect(rendered).to have_selector "document-adder"
    end
  end
end
