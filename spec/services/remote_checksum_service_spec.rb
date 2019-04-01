# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe RemoteChecksumService do
  subject(:remote_checksum_service) { described_class.new(change_set) }

  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:change_set) { ScannedResourceChangeSet.new(scanned_resource) }

  describe ".cloud_storage_driver" do
    let(:driver) { described_class.cloud_storage_driver }

    before do
      Figgy.config["google_cloud_storage"]["credentials"]["private_key"] = OpenSSL::PKey::RSA.new(2048).to_s
      stub_google_cloud_auth
      stub_google_cloud_bucket
    end

    it "accesses a Google Cloud storage bucket resource" do
      expect(driver).to be_a described_class::GoogleCloudStorageDriver
      bucket = driver.bucket("project-figgy-bucket")
      expect(bucket).to be_a Google::Cloud::Storage::Bucket
      expect(bucket.id).to eq "project-figgy-bucket"
    end
  end

  describe "#calculate" do
    before do
      allow(RemoteChecksumJob).to receive(:perform_later)

      remote_checksum_service.calculate
    end

    it "delegates to the asynchronous job" do
      expect(RemoteChecksumJob).to have_received(:perform_later).with(scanned_resource.id.to_s)
    end
  end
end
