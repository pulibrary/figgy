# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Hathi::SubmissionInformationPackage do
  subject(:depositor) { described_class.new(package: package, base_path: deposit_path) }
  let(:file1) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:deposit_path) { Rails.root.join("tmp", "test_hathi") }
  let(:package) { Hathi::ContentPackage.new(resource: resource) }
  let(:resource) do
    file1 = fixture_file_upload("files/example.tif", "image/tiff")
    file2 = fixture_file_upload("files/example.tif", "image/tiff")
    scanned_resource = FactoryBot.create_for_repository(:scanned_resource,
                                                        source_metadata_identifier: "123456",
                                                        files: [file1, file2])
    Wayfinder.for(scanned_resource).members.each_with_index do |file_set, idx|
      pagename = (idx + 1).to_s.rjust(8, "0")
      file_set.ocr_content = "the OCR for page " + pagename
      file_set.hocr_content = "the hOCR for page " + pagename
      Valkyrie::MetadataAdapter.find(:indexing_persister).persister.save(resource: file_set)
    end
    scanned_resource
  end

  before do
    FileUtils.mkdir_p deposit_path
    stub_bibdata(bib_id: "123456")
    depositor.export
  end

  after do
    FileUtils.rm_rf(deposit_path) if File.exist?(deposit_path)
  end

  describe ".deposit" do
    it "builds a zip file on disk" do
      resource_path = deposit_path.join(resource.source_metadata_identifier.first.to_s + ".zip")
      expect(File.exist?(resource_path)).to eq true
    end
  end

  describe "zip contents" do
    it "builds a zip file containing the right content" do
      zip_path = deposit_path.join(resource.source_metadata_identifier.first.to_s + ".zip")
      file_names = []
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          file_names << entry.name
        end
      end
      expect(file_names).to include("00000001.tif")
      expect(file_names).to include("00000001.txt")
      expect(file_names).to include("00000001.html")
      expect(file_names).to include("00000002.tif")
      expect(file_names).to include("00000002.txt")
      expect(file_names).to include("00000002.html")
      expect(file_names).to include("checksum.md5")
      expect(file_names).to include("meta.yml")
    end
  end
end
