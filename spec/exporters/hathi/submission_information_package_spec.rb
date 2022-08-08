# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Hathi::SubmissionInformationPackage do
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
                                                        source_metadata_identifier: "123456",
                                                        ocr_language: "eng",
                                                        files: [file1, file2])
    scanned_resource
  end

  before do
    FileUtils.mkdir_p deposit_path
    stub_catalog(bib_id: "123456")
    depositor.export
  end

  after do
    FileUtils.rm_rf(deposit_path) if File.exist?(deposit_path)
  end

  describe ".deposit" do
    it "creates a SIP directory on disk" do
      resource_path = deposit_path.join(resource.source_metadata_identifier.first.to_s + "_sip")
      expect(File.exist?(resource_path)).to eq true
    end
  end

  describe "sip contents" do
    it "contains the right content" do
      sip_path = deposit_path.join(resource.source_metadata_identifier.first.to_s + "_sip")
      file_names = []
      dir = Dir.new(sip_path)
      dir.each do |f|
        file_names << f
      end
      expect(file_names).to include("00000001.jp2")
      expect(file_names).to include("00000001.txt")
      expect(file_names).to include("00000001.html")
      expect(file_names).to include("00000002.jp2")
      expect(file_names).to include("00000002.txt")
      expect(file_names).to include("00000002.html")
      expect(file_names).to include("checksum.md5")
      expect(file_names).to include("meta.yml")
    end
  end
end
