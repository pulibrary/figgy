# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe BrowseEverythingIngestJob do
  context "when called with a non-existent resource" do
    it "rescues and doesn't retry" do
      allow(Valkyrie.logger).to receive(:warn)

      described_class.perform_now("bla", "ScannedResourcesController", [])

      expect(Valkyrie.logger).to have_received(:warn).with("Unable to find resource with ID: bla")
    end
  end

  context "when called with a container resource" do
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }
    let(:pending_upload_attributes) do
      {
        id: SecureRandom.uuid,
        created_at: Time.current.utc.iso8601,
        file_name: "A shared test folder",
        local_id: "1XzEWzaluDQj0qIH4xqcgxQXcr6",
        url: "https://www.googleapis.com/drive/v3/files/1XzEWzaluDQj0qIH4xqcgxQXcr6?alt=media",
        file_size: 0,
        auth_token: "fake_token",
        auth_header: JSON.generate("Authorization" => "Bearer fake_token"),
        type: "application/x-directory",
        provider: "google_drive"
      }
    end
    let(:pending_upload) do
      PendingUpload.new(pending_upload_attributes)
    end
    let(:pending_uploads) { [pending_upload] }
    let(:pending_upload_ids) { pending_uploads.map(&:id).map(&:to_s) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:change_set_persister) do
      ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
    end
    let(:provider) { instance_double(BrowseEverything::Driver::GoogleDrive) }
    let(:provider_class) { class_double(BrowseEverything::Driver::GoogleDrive) }
    let(:retriever) { instance_double(BrowseEverything::Retriever) }
    let(:auth_token) do
      "fake_token"
    end
    let(:auth_header) do
      JSON.generate("Authorization" => "Bearer #{auth_token}")
    end
    let(:member_resources) do
      [
        {
          id: "1v3gRwJBqxuO4dU1rLHhwCUTTj-Q6XSdN",
          url: "https://www.googleapis.com/drive/v3/files/1v3gRwJBqxuO4dU1rLHhwCUTTj?alt=media",
          auth_token: auth_token,
          auth_header: auth_header,
          file_name: "cea.tif",
          file_size: 270_993,
          container: false,
          provider: "google_drive"
        }
      ]
    end

    before do
      change_set = DynamicChangeSet.new(scanned_resource)
      change_set.validate(pending_uploads: pending_uploads)
      change_set_persister.save(change_set: change_set)

      allow(provider_class).to receive(:authorization_header).and_return(auth_header)
      allow(provider).to receive(:class).and_return(provider_class)
      allow(BrowseEverything::Retriever).to receive(:build_provider).and_return(provider)
      allow(BrowseEverything::Retriever).to receive(:new).and_return(retriever)
      allow(retriever).to receive(:member_resources).and_return(member_resources)
      allow(retriever).to receive(:download).and_return(fixture_file_upload("files/example.tif", "image/tiff"))
    end

    it "recurses through and ingests the member resources" do
      described_class.perform_now(scanned_resource.id.to_s, "ScannedResourcesController", pending_upload_ids)
      updated = adapter.query_service.find_by(id: scanned_resource.id)
      expect(updated.decorate.file_sets).not_to be_empty
      expect(updated.decorate.file_sets.first.title).to eq ["cea.tif"]
    end
  end

  context "when called with a file resource" do
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }
    let(:auth_token) do
      "fake_token"
    end
    let(:auth_header) do
      JSON.generate("Authorization" => "Bearer #{auth_token}")
    end
    let(:pending_upload_attributes) do
      {
        id: SecureRandom.uuid,
        created_at: Time.current.utc.iso8601,
        local_id: "1v3gRwJBqxuO4dU1rLHhwCUTTj",
        url: "https://www.googleapis.com/drive/v3/files/1v3gRwJBqxuO4dU1rLHhwCUTTj?alt=media",
        auth_token: auth_token,
        auth_header: auth_header,
        file_name: "cea.tif",
        file_size: 270_993,
        type: "file",
        provider: "google_drive"
      }
    end
    let(:pending_upload) do
      PendingUpload.new(pending_upload_attributes)
    end
    let(:pending_uploads) { [pending_upload] }
    let(:pending_upload_ids) { pending_uploads.map(&:id).map(&:to_s) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:change_set_persister) do
      ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
    end
    let(:provider) { instance_double(BrowseEverything::Driver::GoogleDrive) }
    let(:provider_class) { class_double(BrowseEverything::Driver::GoogleDrive) }
    let(:retriever) { instance_double(BrowseEverything::Retriever) }

    before do
      change_set = DynamicChangeSet.new(scanned_resource)
      change_set.validate(pending_uploads: pending_uploads)
      change_set_persister.save(change_set: change_set)

      allow(provider_class).to receive(:authorization_header).and_return(auth_header)
      allow(provider).to receive(:class).and_return(provider_class)
      allow(BrowseEverything::Retriever).to receive(:build_provider).and_return(provider)
      allow(BrowseEverything::Retriever).to receive(:new).and_return(retriever)
      allow(retriever).to receive(:download).and_return(fixture_file_upload("files/example.tif", "image/tiff"))
    end

    it "ingests the file resource" do
      expect(scanned_resource.pending_uploads).not_to be_empty
      described_class.perform_now(scanned_resource.id.to_s, "ScannedResourcesController", pending_upload_ids)
      updated = adapter.query_service.find_by(id: scanned_resource.id)
      expect(updated.decorate.file_sets).not_to be_empty
      expect(updated.decorate.file_sets.first.title).to eq ["cea.tif"]
      expect(updated.pending_uploads).to be_empty
    end
  end
end
