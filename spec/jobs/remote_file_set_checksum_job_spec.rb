# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe RemoteFileSetChecksumJob do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:file_set) { scanned_resource.decorate.file_sets.first }
  let(:local_file) { Valkyrie.config.storage_adapter.find_by(id: file_set.original_file.file_identifiers.first.id) }
  let(:md5_hash) { Digest::MD5.file(local_file.disk_path).base64digest }
  let(:crc32c) { Digest::CRC32c.file(local_file.disk_path).base64digest }

  before do
    stub_google_cloud_resource(id: file_set.original_file.id, md5_hash: md5_hash, crc32c: crc32c, local_file_path: local_file.disk_path)
  end

  describe ".perform_now" do
    before do
      Figgy.config["google_cloud_storage"]["credentials"]["private_key"] = OpenSSL::PKey::RSA.new(2048).to_s
    end

    it "uses a remote service to calculate the checksum", rabbit_stubbed: true do
      described_class.perform_now(file_set.id.to_s)
      reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: file_set.id)

      expect(reloaded.remote_checksum).to eq [md5_hash]
    end

    context "when calculating the checksum locally" do
      before do
        allow(Tempfile).to receive(:new).and_call_original
      end

      it "generates the checksum from a locally downloaded file" do
        described_class.perform_now(file_set.id.to_s, local_checksum: true)
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: file_set.id)

        expect(reloaded.remote_checksum).to eq [md5_hash]
        expect(Tempfile).to have_received(:new)
      end
    end
  end
end
