# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe MigrationAdapter do
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) { described_class.new(base_path: Rails.root.join("tmp", "more_files")) }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
  context "when passing a file_mover" do
    let(:storage_adapter) { described_class.new(base_path: Rails.root.join("tmp", "more_files"), file_mover: mover) }
    let(:mover) { FileUtils.method(:cp) }
    it "uses it" do
      allow(FileUtils).to receive(:cp).and_call_original
      allow(FileUtils).to receive(:mv).and_call_original

      storage_adapter.upload(file: file, resource: ScannedResource.new(id: Valkyrie::ID.new("test")))

      expect(FileUtils).not_to have_received(:mv)
    end
  end
  it "can copy a file rather than move it" do
  end
end
