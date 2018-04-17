# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_admin_controls_ephemera_box" do
  let(:box) { FactoryBot.create_for_repository(:ephemera_box) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: box) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:user) }

  before do
    assign :document, solr_document
    sign_in user
    render
  end

  it 'hides the button to attach a hard drive from users' do
    expect(rendered).not_to have_link 'Attach Hard Drive', href: attach_drive_ephemera_box_path(box.id)
  end

  context 'as an admin. user' do
    let(:user) { FactoryBot.create(:admin) }

    it 'displays a button to attach a hard drive' do
      expect(rendered).to have_link 'Attach Hard Drive', href: attach_drive_ephemera_box_path(box.id)
    end
  end
end
