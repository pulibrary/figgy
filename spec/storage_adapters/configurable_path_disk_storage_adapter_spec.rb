# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe ConfigurablePathDiskStorageAdapter do
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) { described_class.new(base_path: Rails.root.join("tmp", "repo_test"), unique_identifier: :testing) }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
  before do
    class Resource < Valkyrie::Resource
      attribute :id, Valkyrie::Types::ID.optional
    end
  end
  after do
    Object.send(:remove_const, :Resource)
  end
  it "creates a bucketed file" do
    stored_file = storage_adapter.upload(file: file, resource: Resource.new(id: "testi-ngthis"))

    expect(stored_file.io.path).to eq Rails.root.join("tmp", "repo_test", "te", "st", "in", "testingthis", "example.tif").to_s
  end
  context "when passed an ID generator" do
    let(:storage_adapter) do
      described_class.new(
        base_path: Rails.root.join("tmp", "repo_test"),
        path_generator: ConfigurablePathDiskStorageAdapter::ContentAddressablePath,
        unique_identifier: :testing
      )
    end
    it "uses it" do
      stored_file = storage_adapter.upload(file: file, resource: Resource.new(id: "test"))

      expect(stored_file.io.path).to eq Rails.root.join("tmp", "repo_test", "547c", "81b0", "80eb", "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c.tif").to_s
    end
    it "only does it once" do
      FileUtils.rm_f(Rails.root.join("tmp", "repo_test", "547c", "81b0", "80eb", "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c.tif"))
      allow(FileUtils).to receive(:mv).and_call_original

      storage_adapter.upload(file: file, resource: Resource.new(id: "test"))
      duplicate_file = fixture_file_upload('files/example.tif', 'image/tiff')
      storage_adapter.upload(file: duplicate_file, resource: Resource.new(id: "test"))

      expect(FileUtils).to have_received(:mv).exactly(1).times
    end
  end
end
