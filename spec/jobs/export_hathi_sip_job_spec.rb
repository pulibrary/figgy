# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe ExportHathiSipJob do
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
    end
    scanned_resource
  end

  before do
    FileUtils.mkdir_p deposit_path
    stub_bibdata(bib_id: "123456")
  end

  after do
    FileUtils.rm_rf(deposit_path) if File.exist?(deposit_path)
  end

  describe ".perform" do
    it "exports the object" do
      described_class.perform_now(resource.id, deposit_path)
      resource_path = deposit_path.join(resource.source_metadata_identifier.first.to_s + ".zip")
      expect(File.exist?(resource_path)).to eq true
    end
  end
end
