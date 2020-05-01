# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrowseEverything::Upload do
  describe "#perform_job" do
    context "when ingesting local files" do
      it "calls ingest asynchronously" do
        session = BrowseEverything::Session.build(provider_id: "file_system").tap(&:save)
        upload = described_class.build(session_id: session.id)
        allow(BrowseEverythingIngestJob).to receive(:perform_later)

        upload.perform_job
        expect(BrowseEverythingIngestJob).to have_received(:perform_later).with(upload_id: upload.id)
      end
    end
    context "when ingesting from the cloud" do
      it "calls ingest synchronously" do
        session = BrowseEverything::Session.build(provider_id: "google_drive").tap(&:save)
        upload = described_class.build(session_id: session.id)
        allow(BrowseEverythingIngestJob).to receive(:perform_now)

        upload.perform_job
        expect(BrowseEverythingIngestJob).to have_received(:perform_now).with(upload_id: upload.id)
      end
    end
  end
end
