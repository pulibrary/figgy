# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Fixity dashboard" do
  with_queue_adapter :inline
  let(:user) { FactoryBot.create(:admin) }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [file]) }
  let(:preservation_object) { Wayfinder.for(scanned_resource).preservation_objects.first }
  let(:file_set) { metadata_adapter.query_service.find_by(id: preservation_object.preserved_object_id) }
  let(:metadata_node) { preservation_object.metadata_node }
  let(:binary_nodes) { preservation_object.binary_nodes }
  let(:cloud_fixity_event) do
    FactoryBot.create_for_repository(:cloud_fixity_event, status: "SUCCESS", resource_id: preservation_object.id, child_id: metadata_node.id, child_property: :metadata_node, current: true)
  end
  let(:failed_cloud_fixity_event) do
    FactoryBot.create_for_repository(:cloud_fixity_event, status: "FAILURE", resource_id: preservation_object.id, child_id: metadata_node.id, child_property: :metadata_node, current: true)
  end
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
    sign_in user
  end

  context "a resource has had its fixity checked by a cloud service provider" do
    scenario "it displays that the event was successful and links to the resource" do
      cloud_fixity_event
      visit fixity_dashboard_path

      expect(page).to have_css "#cloud-fixity-checks table tr td a[href='#{solr_document_path(id: file_set.id)}']", text: file_set.title.first
      expect(page).to have_css "#cloud-fixity-checks table tr td a[href='#{solr_document_path(id: file_set.id)}']", text: metadata_node.label.first
      expect(page).to have_css "#cloud-fixity-checks table tr td", text: "SUCCESS"
    end
  end

  context "the fixity check for a resource by a cloud service provider is for a deleted resource" do
    it "displays that the event was a success and that the preservation object was deleted" do
      cloud_fixity_event
      file_set
      preservation_object
      metadata_adapter.persister.delete(resource: file_set)
      metadata_adapter.persister.delete(resource: preservation_object)
      metadata_adapter.persister.delete(resource: scanned_resource)

      visit fixity_dashboard_path

      expect(page).to have_css "#cloud-fixity-checks table tr td", text: "Preservation Object: #{preservation_object.id} (Deleted)"
      expect(page).to have_css "#cloud-fixity-checks table tr td", text: "SUCCESS"
    end
  end

  context "the fixity check for a resource by a cloud service provider has failed" do
    scenario "it displays that the event was a failure and links to the resource" do
      failed_cloud_fixity_event
      visit fixity_dashboard_path

      expect(page).to have_css "#cloud-fixity-checks table tr td a[href='#{solr_document_path(id: file_set.id)}']", text: file_set.title.first
      expect(page).to have_css "#cloud-fixity-checks table tr td a[href='#{solr_document_path(id: file_set.id)}']", text: metadata_node.label.first
      expect(page).to have_css "#cloud-fixity-checks table tr td", text: "FAILURE"
    end
  end
end
