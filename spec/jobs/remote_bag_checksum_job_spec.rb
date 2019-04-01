# frozen_string_literal: true

require "rails_helper"
include ActionDispatch::TestProcess
require "google/cloud/storage"

RSpec.describe RemoteBagChecksumJob do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:file_set) { scanned_resource.decorate.file_sets.first }
  let(:bag_storage_adapter) { Valkyrie::StorageAdapter.find(:bags) }
  let(:bag_exporter) do
    Bagit::BagExporter.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      storage_adapter: bag_storage_adapter,
      query_service: Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    )
  end
  let(:resource_bag_adapter) { bag_storage_adapter.for(bag_id: scanned_resource.id) }
  let(:local_file) { resource_bag_adapter.storage_adapter }
  let(:local_bag_path) { "#{local_file.bag_path}.zip" }
  let(:md5_hash) { Digest::MD5.file(local_bag_path).base64digest }
  let(:crc32c) { Digest::CRC32c.file(local_bag_path).base64digest }

  before do
    Figgy.config["google_cloud_storage"]["credentials"]["private_key"] = OpenSSL::PKey::RSA.new(2048).to_s
    bag_exporter.export(resource: scanned_resource)
    allow(RemoteChecksumJob).to receive(:perform_later)
  end

  context "when compressing into a ZIP file" do
    let(:local_bag_path) { "#{local_file.bag_path}.zip" }

    before do
      RemoteBagChecksumService::ZipCompressedBag.build(path: local_file.bag_path)
      stub_google_cloud_resource(id: scanned_resource.id, md5_hash: md5_hash, crc32c: crc32c, local_file_path: local_bag_path)
      Figgy.config["google_cloud_storage"]["bags"]["format"] = "application/zip"
    end

    describe ".perform_now" do
      it "generates the checksum and appends it to the resource", rabbit_stubbed: true do
        described_class.perform_now(scanned_resource.id.to_s)
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)

        file_sets = reloaded.decorate.file_sets
        expect(file_sets.length).to eq 2
        expect(file_sets.last.file_metadata.length).to eq 1
        expect(file_sets.last.file_metadata.last.file_identifiers).to eq ["https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/#{scanned_resource.id}"]
        expect(RemoteChecksumJob).to have_received(:perform_later)
      end
    end
  end

  context "when calculating the checksum for an uncompressed bag" do
    let(:cloud_api_object1) { instance_double(Google::Apis::StorageV1::Object) }
    let(:cloud_file1) { instance_double(Google::Cloud::Storage::File) }

    before do
      stub_google_cloud_auth
      stub_google_cloud_bucket

      allow(cloud_api_object1).to receive(:id).and_return("test-id-#{SecureRandom.uuid}")
      allow(cloud_api_object1).to receive(:self_link).and_return("https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/test-id-#{SecureRandom.uuid}")

      allow(cloud_file1).to receive(:name).and_return("bag_file_1")
      allow(cloud_file1).to receive(:content_type).and_return("application/octet-stream")
      allow(cloud_file1).to receive(:gapi).and_return(cloud_api_object1)
      allow_any_instance_of(RemoteChecksumService::GoogleCloudStorageDriver).to receive(:file).and_return(cloud_file1)
    end

    describe ".perform_now" do
      it "generates the checksum and appends it to the resource", rabbit_stubbed: true do
        described_class.perform_now(scanned_resource.id.to_s, compress_bag: false)
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)
        file_sets = reloaded.decorate.file_sets
        expect(file_sets.length).to eq 2
        expect(file_sets.last.file_metadata.length).to eq 1
        expect(file_sets.last.file_metadata.last.file_identifiers).to eq [cloud_api_object1.self_link]
        expect(RemoteChecksumJob).to have_received(:perform_later)
      end
    end
  end

  context "when compressing into a TAR file" do
    let(:local_bag_path) { "#{local_file.bag_path}.tgz" }

    before do
      RemoteBagChecksumService::TarCompressedBag.build(path: local_file.bag_path)
      stub_google_cloud_resource(id: scanned_resource.id, md5_hash: md5_hash, crc32c: crc32c, local_file_path: local_bag_path)
    end

    describe ".perform_now" do
      it "generates the checksum and appends it to the resource", rabbit_stubbed: true do
        described_class.perform_now(scanned_resource.id.to_s)
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)
        file_sets = reloaded.decorate.file_sets
        expect(file_sets.length).to eq 2
        expect(file_sets.last.file_metadata.length).to eq 1
        expect(file_sets.last.file_metadata.last.file_identifiers).to eq ["https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/#{scanned_resource.id}"]
        expect(RemoteChecksumJob).to have_received(:perform_later)
      end
    end
  end
end
