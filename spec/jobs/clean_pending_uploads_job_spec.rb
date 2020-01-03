# frozen_string_literal: true
require "rails_helper"

RSpec.describe CleanPendingUploadsJob do
  with_queue_adapter :inline

  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:resource1) do
    FactoryBot.create_for_repository(
      :pending_scanned_resource,
      pending_uploads: []
    )
  end
  let(:resource_id) { resource1.id }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource2) do
    FactoryBot.create_for_repository(
      :complete_scanned_resource,
      files: [file]
    )
  end
  let(:pending_upload) do
    # rubocop:disable Rails/FilePath
    PendingUpload.new(
      id: SecureRandom.uuid,
      created_at: Time.current.utc.iso8601,
      expires: "2018-06-06T22:12:11Z",
      file_name: "example.tif",
      file_size: "1874822",
      url: "file://#{Rails.root.join('spec', 'fixtures', 'files', 'example.tif')}"
    )
    # rubocop:enable Rails/FilePath
  end
  let(:resource3) do
    FactoryBot.create_for_repository(
      :pending_scanned_resource,
      pending_uploads: [pending_upload]
    )
  end

  describe "#perform" do
    before do
      stub_ezid(shoulder: shoulder, blade: blade)
      allow(Valkyrie.logger).to receive(:info)
      resource1
    end

    it "deletes resources with failed file uploads" do
      described_class.perform_now
      expect { query_service.find_by(id: resource_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      expect(Valkyrie.logger).to have_received(:info).with("Deleted a resource with failed uploads with the title: #{resource1.decorate.first_title} (#{resource_id})")
    end

    it "does not delete successful file uploads" do
      resource2
      resource3
      described_class.perform_now
      # Ensure that the Resource with the PendingUploads has not been deleted
      found_resource3 = query_service.find_by(id: resource3.id)
      expect(found_resource3).not_to be_nil

      found_resource2 = query_service.find_by(id: resource2.id)
      expect(found_resource2.decorate.file_sets).not_to be_empty
      expect(found_resource2.decorate.file_sets.first).to be_a FileSet
      expect(found_resource2.id).to eq(found_resource2.id)

      expect { query_service.find_by(id: resource_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      expect(Valkyrie.logger).to have_received(:info).with("Deleted a resource with failed uploads with the title: #{resource1.decorate.first_title} (#{resource_id})")
    end

    context "when being processed as a dry run" do
      it "does not delete the resources with failed uploads but logs the resource IDs" do
        described_class.perform_now(dry_run: true)

        found_resource = query_service.find_by(id: resource_id)
        expect(found_resource).not_to be_nil
        expect(Valkyrie.logger).to have_received(:info).with("Found #{found_resource.decorate.first_title} (#{resource_id}) as an uploaded resource without any FileSets - this would normally be deleted by CleanPendingUploadsJob")
      end
    end
  end
end
