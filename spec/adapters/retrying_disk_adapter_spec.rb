# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe RetryingDiskAdapter do
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) do
    described_class.new(
      inner_adapter
    )
  end
  let(:inner_adapter) { Valkyrie::StorageAdapter.find(:disk) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  context "when upload fails because of an Errno::EPIPE" do
    it "retries" do
      counts = 0
      allow(storage_adapter.inner_storage_adapter).to receive(:upload).and_wrap_original do |method, *args|
        counts += 1
        raise Errno::EPIPE if counts == 1
        method.call(*args)
      end

      uploaded_file = storage_adapter.upload(file: file, resource: ScannedResource.new(id: SecureRandom.uuid), original_filename: "test.tiff")

      expect(uploaded_file.id).to be_present
    end
    it "gives up eventually" do
      allow(storage_adapter.inner_storage_adapter).to receive(:upload).and_raise(Errno::EPIPE)

      expect { storage_adapter.upload(file: file, resource: ScannedResource.new(id: SecureRandom.uuid), original_filename: "test.tiff") }.to raise_error Errno::EPIPE
    end
  end
  context "when upload fails because of an Errno::EAGAIN" do
    it "tries again" do
      counts = 0
      allow(storage_adapter.inner_storage_adapter).to receive(:upload).and_wrap_original do |method, *args|
        counts += 1
        raise Errno::EAGAIN if counts == 1
        method.call(*args)
      end

      uploaded_file = storage_adapter.upload(file: file, resource: ScannedResource.new(id: SecureRandom.uuid), original_filename: "test.tiff")

      expect(uploaded_file.id).to be_present
    end
  end

  context "when upload fails because of an Errno::EIO" do
    it "tries again" do
      counts = 0
      allow(storage_adapter.inner_storage_adapter).to receive(:upload).and_wrap_original do |method, *args|
        counts += 1
        raise Errno::EIO if counts == 1
        method.call(*args)
      end

      uploaded_file = storage_adapter.upload(file: file, resource: ScannedResource.new(id: SecureRandom.uuid), original_filename: "test.tiff")

      expect(uploaded_file.id).to be_present
    end
  end

  context "when upload fails because of an Errno::ECONNRESET" do
    it "tries again" do
      counts = 0
      allow(storage_adapter.inner_storage_adapter).to receive(:upload).and_wrap_original do |method, *args|
        counts += 1
        raise Errno::EIO if counts == 1
        method.call(*args)
      end

      uploaded_file = storage_adapter.upload(file: file, resource: ScannedResource.new(id: SecureRandom.uuid), original_filename: "test.tiff")

      expect(uploaded_file.id).to be_present
    end
  end
end
