# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Hathi::ImageMetadata do
  subject(:adapter) { described_class.new(resource: dummy_resource) }
  with_queue_adapter :inline
  let(:dummy_resource) do
    file1 = fixture_file_upload("files/example.tif", "image/tiff")
    file2 = fixture_file_upload("files/example.tif", "image/tiff")
    scanned_resource = FactoryBot.create_for_repository(:scanned_resource,
                                                        source_metadata_identifier: "123456",
                                                        ocr_language: "eng",
                                                        files: [file1, file2])
    scanned_resource
  end

  before do
    stub_bibdata(bib_id: "123456")
  end

  it "supplies a capture date" do
    value = adapter.capture_date
    expect(value).to eq("2014-07-01T05:31:54")
  end

  it "supplies a scanner make" do
    expect(adapter.scanner_make).to eq("Phase One")
  end

  it "supplies a scanner model" do
    expect(adapter.scanner_model).to eq("P65+")
  end

  it "supplies a scanner user" do
    expect(adapter.scanner_user).to eq("\"Princeton University Library: Digital Photography Studio\"")
  end

  it "knows it isn't bitonal" do
    expect(adapter.bitonal?).to be false
  end

  it "supplies image resolution" do
    expect(adapter.resolution).to eq(1120)
  end

  it "supplies a reading order" do
    expect(adapter.reading_order).to eq(%("left-to-right"))
  end

  it "supplies page data"
end
