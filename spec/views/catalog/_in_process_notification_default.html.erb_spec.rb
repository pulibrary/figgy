# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_in_process_notification_default" do
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [file_set1.id, file_set2.id]) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: scanned_resource) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:admin) }
  let(:file_set1) { FactoryBot.create_for_repository(:file_set, processing_status: "in process") }
  let(:file_set2) { FactoryBot.create_for_repository(:file_set, processing_status: "processed") }

  before do
    assign :resource, scanned_resource
    assign :document, solr_document
    sign_in user
    render
  end
  context "when there's file sets in process" do
    it "gives an alert" do
      expect(rendered).to have_text "Files Processed: 1 / 2"
    end
  end
  context "when there's pending uploads" do
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, pending_uploads: PendingUpload.new) }
    it "gives an alert" do
      expect(rendered).to have_text "Pending Uploads: 1"
    end
  end
end
