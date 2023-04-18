# frozen_string_literal: true
require "rails_helper"

RSpec.describe AutoCompleter do
  with_queue_adapter :inline
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  context "when there are complete_when_processed resources ready for completion" do
    it "marks them complete" do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
      complete_resource = FactoryBot.create_for_repository(:complete_open_scanned_resource)
      to_be_completed_resource = FactoryBot.create_for_repository(:scanned_resource, files: [file], state: "complete_when_processed")
      no_files_resource = FactoryBot.create_for_repository(:scanned_resource, state: "complete_when_processed")
      unprocessed_file_set = FactoryBot.create_for_repository(:file_set, processing_status: "in process")
      unprocessed_resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [unprocessed_file_set.id], state: "complete_when_processed")
      csp = ChangeSetPersister.default

      AutoCompleter.run

      # The to be completed resource is marked complete.
      expect(csp.query_service.find_by(id: to_be_completed_resource.id).state).to eq ["complete"]
      # The ineligible resources haven't changed.
      expect(csp.query_service.find_by(id: complete_resource.id).updated_at).to eq complete_resource.updated_at
      expect(csp.query_service.find_by(id: no_files_resource.id).updated_at).to eq no_files_resource.updated_at
      expect(csp.query_service.find_by(id: unprocessed_resource.id).updated_at).to eq unprocessed_resource.updated_at
    end
  end
  context "when one eligible resource ready for completion errors" do
    it "notifies and completes the others" do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
      allow(Honeybadger).to receive(:notify)
      to_be_completed_resource1 = FactoryBot.create_for_repository(:scanned_resource, files: [file], state: "complete_when_processed")
      to_be_completed_resource2 = FactoryBot.create_for_repository(:scanned_resource, files: [file2], state: "complete_when_processed")
      csp = ChangeSetPersister.default
      # Stub IdentifierService to make an error happen.
      message_calls = 0
      allow(IdentifierService).to receive(:mint_or_update) do
        message_calls += 1
        raise "Broken" if message_calls == 1
      end

      AutoCompleter.run

      # The resource that errored isn't changed
      expect(csp.query_service.find_by(id: to_be_completed_resource1.id).state).to eq ["complete_when_processed"]
      expect(Honeybadger).to have_received(:notify).exactly(1).times
      # The valid to be completed resource is marked complete.
      expect(csp.query_service.find_by(id: to_be_completed_resource2.id).state).to eq ["complete"]
    end
  end
end
