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

    it "has paths to jp2 files" do
      page = package.pages.first
      expect(page.derivative_path.ftype).to eq "file"
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
end
