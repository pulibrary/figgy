# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_admin_controls_ephemera_folder" do
  let(:folder) { FactoryGirl.create_for_repository(:ephemera_folder) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: folder) }
  let(:solr_document) { SolrDocument.new(document) }

  before do
    solr.persister.save(resource: parent)
    assign :document, solr_document
    render
  end

  context "when the parent is a box" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_box, member_ids: [folder.id]) }

    it 'has a button to attach a new folder to the box ' do
      expect(rendered).to have_link 'Attach Another Folder', href: new_ephemera_folder_path(parent_id: parent.id)
    end
  end

  context "when the parent is a project" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_project, member_ids: [folder.id]) }

    it 'has a button to attach a new folder to the project ' do
      expect(rendered).to have_link 'Attach Another Folder', href: boxless_new_ephemera_folder_path(parent_id: parent.id)
    end
  end
end
