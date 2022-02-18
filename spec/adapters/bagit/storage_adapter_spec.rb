# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe Bagit::StorageAdapter do
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) do
    described_class.new(
      base_path: Rails.root.join("tmp", "bags")
    ).for(bag_id: "123456789")
  end
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  before do
    FileUtils.rm_rf(Rails.root.join("tmp", "bags"))
  end
  it "creates bag manifests on upload and deletes entries on delete" do
    output_file = storage_adapter.upload(file: file, original_filename: "test.tif", resource: ScannedResource.new)
    sha256_manifest = File.read(storage_adapter.bag_path.join("manifest-sha256.txt")).split("\n")
    sha1_manifest = File.read(storage_adapter.bag_path.join("manifest-sha1.txt")).split("\n")
    md5_manifest = File.read(storage_adapter.bag_path.join("manifest-md5.txt")).split("\n")
    data_path = "data/#{Pathname.new(output_file.id.to_s.gsub("bag://", "")).basename}"
    expect(sha256_manifest[0]).to eq "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c  #{data_path}"
    expect(sha1_manifest[0]).to eq "1b95e65efc3aefeac1f347218ab6f193328d70f5  #{data_path}"
    expect(md5_manifest[0]).to eq "2a28fb702286782b2cbf2ed9a5041ab1  #{data_path}"
    storage_adapter.delete(id: output_file.id)
    sha256_manifest = File.read(storage_adapter.bag_path.join("manifest-sha256.txt")).split("\n")
    sha1_manifest = File.read(storage_adapter.bag_path.join("manifest-sha1.txt")).split("\n")
    md5_manifest = File.read(storage_adapter.bag_path.join("manifest-md5.txt")).split("\n")
    expect(sha256_manifest).to be_blank
    expect(sha1_manifest).to be_blank
    expect(md5_manifest).to be_blank
  end
end
