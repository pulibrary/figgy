# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_admin_controls_ephemera_term" do
  let(:term) { FactoryBot.create_for_repository(:ephemera_term) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: term) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:user) }

  before do
    assign :document, solr_document
    sign_in user
    render
  end

  it "hides the edit link from users" do
    expect(rendered).not_to have_link "Edit This Ephemera Term"
  end

  it "hides the delete link from users" do
    expect(rendered).not_to have_link "Delete This Ephemera Term"
  end

  context "as an admin. user" do
    let(:user) { FactoryBot.create(:admin) }
    it "renders the edit link" do
      expect(rendered).to have_link "Edit This Ephemera Term", href: edit_ephemera_term_path(term.id)
    end
  end

  context "as an admin. user" do
    let(:user) { FactoryBot.create(:admin) }
    it "renders the delete link" do
      expect(rendered).to have_link "Delete This Ephemera Term", href: ephemera_term_path(term.id)
    end
  end
end
