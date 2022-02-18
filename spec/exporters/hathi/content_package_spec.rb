# frozen_string_literal: true

require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Hathi::ContentPackage do
  subject(:package) { described_class.new(resource: dummy_resource) }
  with_queue_adapter :inline
  let(:dummy_resource) do
    file1 = fixture_file_upload("files/example.tif", "image/tiff")
    file2 = fixture_file_upload("files/example.tif", "image/tiff")
    scanned_resource = FactoryBot.create_for_repository(:scanned_resource,
      source_metadata_identifier: "123456",
      ocr_language: "eng",
      viewing_direction: ["right-to-left"],
      files: [file1, file2])
    scanned_resource
  end

  before do
    stub_bibdata(bib_id: "123456")
  end

  describe ".id" do
    it "has the right identifier" do
      expect(package.id).to eq("123456")
    end
  end

  # stub the resource.source_metadata_identifier to return nil
  describe "defaults" do
    before do
      allow(package.resource).to receive(:source_metadata_identifier).and_return(nil)
      allow(package.resource).to receive(:viewing_direction).and_return(nil)
    end

    it "defaults to the resource id" do
      resource_id_string = package.resource.id.to_s
      expect(package.id).to eq(resource_id_string)
    end

    it "defaults to \"left-to-right\" reading order" do
      expect(package.reading_order).to eq("left-to-right")
    end
  end

  describe "properties" do
    it "has a capture date" do
      expect(package.capture_date).to eq("2014-07-01T05:31:54")
    end

    it "supplies a scanner make" do
      expect(package.scanner_make).to eq("Phase One")
    end

    it "supplies a scanner model" do
      expect(package.scanner_model).to eq("P65+")
    end

    it "supplies a scanner user" do
      expect(package.scanner_user).to eq("Princeton University Library: Digital Photography Studio")
    end

    it "knows it isn't bitonal" do
      expect(package.bitonal?).to be false
    end

    it "supplies image resolution" do
      expect(package.resolution).to eq(1120)
    end

    it "supplies a reading order" do
      expect(package.reading_order).to eq("right-to-left")
    end
  end

  describe "metadata" do
    it "has metadata" do
      expect(package.metadata["capture_date"]).to eq(package.capture_date)
      expect(package.metadata["scanner_make"]).to eq(package.scanner_make)
      expect(package.metadata["scanner_model"]).to eq(package.scanner_model)
      expect(package.metadata["scanner_user"]).to eq(package.scanner_user)
      expect(package.metadata["reading_order"]).to eq(package.reading_order)
    end
  end

  describe ".pages" do
    it "has the right number of pages" do
      expect(package.pages.count).to eq 2
    end

    it "has the right page names" do
      expect(package.pages.first.image_filename).to eq "00000001.jp2"
      expect(package.pages[1].image_filename).to eq "00000002.jp2"
    end

    it "has path to image file" do
      page = package.pages.first
      expect(page.path_to_file.ftype).to eq "file"
    end

    it "has text streams" do
      page = package.pages.first
      expect(page.to_txt).to be_present
    end

    it "has html streams" do
      page = package.pages.first
      expect(page.to_html).to be_present
    end
  end

  describe "original page image file" do
    subject(:page) { Hathi::ContentPackage::OriginalPage.new(wayfinder.members.first, "opage") }
    let(:wayfinder) { Wayfinder.for(package.resource) }

    it "is of the right type" do
      expect(page.image_filename).to eq "opage.tiff"
    end

    it "has an ocr file with the right name" do
      expect(page.ocr_filename).to eq "opage.txt"
    end
    it "has an hocr file with the right name" do
      expect(page.hocr_filename).to eq "opage.html"
    end
  end

  describe "derivative page image file" do
    subject(:page) { Hathi::ContentPackage::DerivativePage.new(wayfinder.members.first, "opage") }
    let(:wayfinder) { Wayfinder.for(package.resource) }
    it "is of the right type" do
      expect(page.image_filename).to eq "opage.jp2"
    end
  end
end
