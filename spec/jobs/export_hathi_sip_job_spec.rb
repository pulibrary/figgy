# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe ExportHathiSipJob do
  subject(:depositor) { described_class.new(package: package, base_path: deposit_path) }
  let(:file1) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:deposit_path) { Rails.root.join("tmp", "test_hathi#{ENV['TEST_ENV_NUMBER']}") }
  let(:package) { Hathi::ContentPackage.new(resource: resource) }
  with_queue_adapter :inline
  let(:resource) do
    file1 = fixture_file_upload("files/example.tif", "image/tiff")
    file2 = fixture_file_upload("files/example.tif", "image/tiff")
    scanned_resource = FactoryBot.create_for_repository(:scanned_resource,
                                                        source_metadata_identifier: "991234563506421",
                                                        ocr_language: "eng",
                                                        files: [file1, file2])
    scanned_resource
  end

  before do
    FileUtils.mkdir_p deposit_path
    stub_catalog(bib_id: "991234563506421")
  end

  after do
    FileUtils.rm_rf(deposit_path) if File.exist?(deposit_path)
  end

  describe ".perform" do
    it "exports the object" do
      described_class.perform_now(resource.id, deposit_path)
      resource_path = deposit_path.join(resource.source_metadata_identifier.first.to_s + "_sip")
      expect(File.exist?(resource_path)).to eq true
    end
  end
end
