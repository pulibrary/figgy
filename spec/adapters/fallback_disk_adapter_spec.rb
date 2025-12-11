# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe FallbackDiskAdapter do
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) do
    described_class.new(
      primary_adapter: primary_adapter,
      fallback_adapter: fallback_adapter
    )
  end
  let(:primary_adapter) { Valkyrie::StorageAdapter.find(:disk).primary_adapter }
  let(:fallback_adapter) { Valkyrie::StorageAdapter.find(:disk).fallback_adapter }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file_2) { fixture_file_upload("files/example.tif", "image/tiff") }

  describe "#find_by" do
    context "when reading from the primary adapter fails" do
      it "falls back to the fallback adapter" do
        allow(Rails.logger).to receive(:warn)
        resource = ScannedResource.new(id: SecureRandom.uuid)
        # Put the file in both places.
        uploaded_file = primary_adapter.upload(file: file, original_filename: "foo.jpg", resource: resource)
        new_path = Pathname.new(uploaded_file.disk_path.to_s.gsub(Figgy.config["repository_path"], Figgy.config["fallback_repository_path"]))
        FileUtils.mkdir_p(new_path)
        FileUtils.cp(uploaded_file.disk_path, new_path)

        file_double = instance_double(File)
        allow(file_double).to receive(:read) do
          # This is what happens when Tigerdata has a database entry, but can't
          # connect to the Isilon. It can get File.size and File.stat, but
          # reading any bytes errors.
          raise Errno::EIO
        end
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(uploaded_file.disk_path, "rb").and_yield(file_double)

        reloaded_uploaded_file = storage_adapter.find_by(id: uploaded_file.id)
        expect(reloaded_uploaded_file.id).to eq uploaded_file.id
        expect(Rails.logger).to have_received(:warn).with(/Disk adapter used fallback for /)
      end
    end
    context "when it's not found in primary adapter" do
      it "falls back to read from the fallback adapter" do
        allow(Rails.logger).to receive(:warn)
        resource = ScannedResource.new(id: SecureRandom.uuid)
        # The use case is we have a folder of files that are being moved to a new
        # folder. Check that old folder if the new one doesn't have it yet.
        uploaded_file = primary_adapter.upload(file: file, original_filename: "foo.jpg", resource: resource)
        new_path = Pathname.new(uploaded_file.disk_path.to_s.gsub(Figgy.config["repository_path"], Figgy.config["fallback_repository_path"]))
        FileUtils.mkdir_p(new_path)
        FileUtils.mv(uploaded_file.disk_path, new_path)

        reloaded_uploaded_file = storage_adapter.find_by(id: uploaded_file.id)
        expect(reloaded_uploaded_file.id).to eq uploaded_file.id
        expect(Rails.logger).to have_received(:warn).with(/Disk adapter used fallback for /)
      end
      it "can handle the directory for fallback adapter not existing" do
        resource = ScannedResource.new(id: SecureRandom.uuid)
        adapter = described_class.new(
          primary_adapter: primary_adapter,
          fallback_adapter:
            Valkyrie::Storage::Disk.new(
              base_path: "/opt/something/not/real",
              file_mover: lambda { |old_path, new_path|
                FileUtils.mv(old_path, new_path)
                FileUtils.chmod(0o644, new_path)
              }
            )
        )
        uploaded_file = primary_adapter.upload(file: file, original_filename: "foo.jpg", resource: resource)
        primary_adapter.delete(id: uploaded_file.id)

        expect { adapter.find_by(id: uploaded_file.id) }.to raise_error Valkyrie::StorageAdapter::FileNotFound
      end
    end
  end
end
