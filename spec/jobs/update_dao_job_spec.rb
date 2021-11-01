# frozen_string_literal: true
require "rails_helper"

RSpec.describe UpdateDaoJob do
  describe ".perform" do
    context "when an error is raised by Aspace that an archival object was not found" do
      it "logs the error" do
        allow(Rails.logger).to receive(:error)

        stub_aspace_login

        stub_aspace(pulfa_id: "MC230_c117")
        stub_find_archival_object_not_found(component_id: "MC230_c117")

        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "MC230_c117")

        described_class.perform_now(resource.id)
        expect(Rails.logger).to have_received(:error).with("Archival object not found: Aspace::Client::ArchivalObjectNotFound")
      end
    end
  end
end
