# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_admin_controls_default" do
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: scanned_resource) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:user) }

  before do
    assign :resource, scanned_resource
    assign :document, solr_document
    sign_in user
    render
  end

  it "hides the edit link for resources" do
    expect(rendered).not_to have_link "Edit This Scanned Resource", href: edit_scanned_resource_path(id: scanned_resource.id)
  end

  it "hides the file manager link for resources" do
    expect(rendered).not_to have_link "File Manager", href: file_manager_scanned_resource_path(id: scanned_resource.id)
  end

  it "hides the structure editor link for resources" do
    expect(rendered).not_to have_link "Structure Manager", href: structure_scanned_resource_path(id: scanned_resource.id)
  end

  it "hides links for attaching child resources" do
    expect(rendered).not_to have_button "Attach Child"
  end

  it "hides the delete link for resources" do
    expect(rendered).not_to have_link "Delete This Scanned Resource", href: scanned_resource_path(id: scanned_resource.id)
  end

  context "as an admin. user" do
    let(:user) { FactoryBot.create(:admin) }

    it "renders the edit link for resources" do
      expect(rendered).to have_link "Edit This Scanned Resource", href: edit_scanned_resource_path(id: scanned_resource.id)
    end

    it "renders the file manager link for resources" do
      expect(rendered).to have_link "File Manager", href: file_manager_scanned_resource_path(id: scanned_resource.id)
    end

    it "renders the order_manager link for resources" do
      expect(rendered).to have_link "Order Manager", href: order_manager_scanned_resource_path(id: scanned_resource.id)
    end

    it "renders the structure manager link for resources" do
      expect(rendered).to have_link "Structure Manager", href: structure_scanned_resource_path(id: scanned_resource.id)
    end

    it "renders links for attaching child resources" do
      expect(rendered).to have_link "Attach Scanned Resource", href: parent_new_scanned_resource_path(scanned_resource)
    end

    it "renders the delete link for resources" do
      expect(rendered).to have_link "Delete This Scanned Resource", href: scanned_resource_path(id: scanned_resource.id)
    end

    context "with a scanned map resource" do
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_map) }

      it "renders links for attaching a child scanned map resource and raster resource" do
        expect(rendered).to have_link "Attach Scanned Map", href: parent_new_scanned_map_path(parent_id: scanned_resource.id)
        expect(rendered).to have_link "Attach Raster Resource", href: parent_new_raster_resource_path(parent_id: scanned_resource.id)
      end
    end
  end
end
