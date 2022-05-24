# frozen_string_literal: true
require "rails_helper"

RSpec.describe RefreshRemoteMetadataJob do
  describe "#perform" do
    let(:collection_code) { "C0652" }
    let(:component_id) { "C0652_c0383" }
    let(:change_set_persister) { ChangeSetPersister.default }
    let(:query_service) { change_set_persister.query_service }

    context "when the metadata has changed" do
      it "updates the metadata" do
        stub_findingaid(pulfa_id: component_id)
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: component_id, archival_collection_code: collection_code)
        change_set = ChangeSet.for(resource)
        change_set.validate(imported_metadata: nil)
        change_set_persister.save(change_set: change_set)

        reloaded_resource = query_service.find_by(id: resource.id)
        expect(reloaded_resource.primary_imported_metadata.extent).to be_nil

        described_class.perform_now(id: resource.id)
        reloaded_resource = query_service.find_by(id: resource.id)
        expect(reloaded_resource.primary_imported_metadata.extent).to eq ["1 item"]
      end
    end

    context "when the metadata has not changed" do
      it "doesn't persist the resource" do
        stub_findingaid(pulfa_id: component_id)
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: component_id, archival_collection_code: collection_code)
        change_set = ChangeSet.for(resource)
        change_set.validate(refresh_remote_metadata: "1")
        change_set_persister.save(change_set: change_set)

        reloaded_resource = query_service.find_by(id: resource.id)
        expect(reloaded_resource.primary_imported_metadata.extent).not_to be_nil

        csp_mock = instance_double(ChangeSetPersister::Basic)
        allow(ChangeSetPersister).to receive(:default).and_return(csp_mock)
        allow(csp_mock).to receive(:query_service).and_return(query_service)
        allow(csp_mock).to receive(:save)

        described_class.perform_now(id: resource.id)
        expect(csp_mock).not_to have_received(:save)
      end
    end

    context "with a SimpleResource" do
      it "exits without erroring" do
        stub_findingaid(pulfa_id: component_id)
        resource = FactoryBot.create_for_repository(:simple_resource, source_metadata_identifier: component_id, archival_collection_code: collection_code)

        expect { described_class.perform_now(id: resource.id) }.not_to raise_error
      end
    end
  end
end
