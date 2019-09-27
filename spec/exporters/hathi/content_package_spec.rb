# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Hathi::ContentPackage do
  subject(:package) { described_class.new(resource: dummy_resource) }

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

  describe ".id" do
    it "has the right identifier" do
      expect(package.id).to eq("123456")
    end
  end

  # stub the resource.source_metadata_identifier to return nil
  describe "default id" do
    before do
      allow(package.resource).to receive(:source_metadata_identifier).and_return(nil)
    end

    it "defaults to the resource id" do
      resource_id_string = package.resource.id.to_s
      expect(package.id).to eq(resource_id_string)
    end
  end

  describe ".pages" do
    it "has the right number of pages" do
      expect(package.pages.count).to eq 2
    end

    it "has the right page names" do
      expect(package.pages.first.name).to eq "00000001"
      expect(package.pages[1].name).to eq "00000002"
    end

    it "has paths to tiff files" do
      page = package.pages.first
      expect(page.tiff_path.ftype).to eq "file"
    end

    it "has text streams" do
      page = package.pages.first
      expect(page.to_txt).to eq("the OCR for page 00000001")
    end

    it "has html streams" do
      page = package.pages.first
      expect(page.to_html).to eq("the hOCR for page 00000001")
    end
  end
end
