# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Hathi::ImageMetadata do
  subject(:adapter) { described_class.new(resource: dummy_resource) }

  let(:dummy_resource) do
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
    stub_bibdata(bib_id: "123456")
  end

  it "supplies a capture date" do
    value = adapter.capture_date
    expect(value).to eq("2014:12:03 12:40:50")
  end

  it "supplies a scanner make" do
    expect(adapter.scanner_make).to eq("Phase One")
  end
  it "supplies a scanner model" do
    expect(adapter.scanner_model).to eq("P65+")
  end

  it "knows it isn't bitonal" do
    expect(adapter.bitonal?).to be false
  end

  it "supplies image resolution" do
    expect(adapter.resolution).to eq(1120)
  end

  it "supplies a scanning order"
  it "supplies a reading order"
  it "supplies page data"
end
