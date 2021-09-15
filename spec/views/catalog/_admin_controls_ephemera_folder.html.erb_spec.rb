# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_admin_controls_ephemera_folder" do
  let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: folder) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:user) }

  before do
    solr.persister.save(resource: parent, external_resource: true)
    assign :document, solr_document
    sign_in user
    render
  end

  context "when the parent is a box" do
    let(:parent) { FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id]) }

    it "hides the button to attach a new folder to the box " do
      expect(rendered).not_to have_link "Attach Another Folder"
    end
  end

  context "when the parent is a project" do
    let(:parent) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id]) }

    it "hides the button to attach a new folder to the project " do
      expect(rendered).not_to have_link "Attach Another Folder"
    end
  end

  context "as an admin. user" do
    let(:user) { FactoryBot.create(:admin) }

    context "when the parent is a box" do
      let(:parent) { FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id]) }

      it "has a button to attach a new folder to the box " do
        expect(rendered).to have_link "Attach Another Folder", href: new_ephemera_folder_path(parent_id: parent.id)
      end

      it "has a button to manage files" do
        expect(rendered).to have_link "File Manager", href: file_manager_ephemera_folder_path(folder.id)
      end

      it "has a button to manage order" do
        expect(rendered).to have_link "Order Manager", href: order_manager_ephemera_folder_path(folder.id)
      end
    end

    context "when the parent is a project" do
      let(:parent) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id]) }

      it "has a button to attach a new folder to the project " do
        expect(rendered).to have_link "Attach Another Folder", href: boxless_new_ephemera_folder_path(parent_id: parent.id)
      end
    end
  end
end
