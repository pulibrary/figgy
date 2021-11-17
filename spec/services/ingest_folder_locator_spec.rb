# frozen_string_literal: true
require "rails_helper"

describe IngestFolderLocator do
  subject(:locator) { described_class.new(id: id) }
  let(:id) { "123456" }
  let(:upload_path_value) { Rails.root.join("spec", "fixtures", "staged_files").to_s }

  describe "#upload_path_value" do
    it "parses the upload path from the BrowseEverything config." do
      expect(locator.upload_path_value).to eq upload_path_value
    end
  end

  describe "#root_path" do
    let(:root_path) { Pathname.new(upload_path_value).join("studio_new/DPUL") }
    it "generates the root path from the upload directory" do
      expect(locator.root_path).to eq root_path
    end
  end

  describe "#exists?" do
    it "determines if the folder location exists on disk" do
      expect(locator.exists?).to be true
    end
  end

  describe "#location" do
    it "retrieves relative root" do
      expect(locator.location).to be_a Pathname
      expect(locator.location.to_s).to eq "Santa/ready/123456"
    end
  end

  describe "#file_count" do
    it "counts the files" do
      expect(locator.file_count).to eq 2
    end
  end

  describe "#volume_count" do
    let(:id) { "4609321" }
    it "counts the directories" do
      expect(locator.volume_count).to eq 2
    end
  end

  describe "#folder_pathname" do
    let(:folder_pathname) { Pathname.new(File.join(upload_path_value, "studio_new", "DPUL", "Santa", "ready", "123456")) }

    it "constructs a Pathname for the folder" do
      expect(locator.folder_pathname).to eq folder_pathname
    end

    context "without a valid folder path" do
      subject(:locator) { described_class.new(id: "foo") }

      it "returns nil" do
        expect(locator.folder_pathname).to be nil
      end
    end
  end

  describe "#to_h" do
    subject(:hsh) { locator.to_h }
    it "generates a hash with the relevant values" do
      expect(hsh[:exists]).to be true
      expect(hsh[:location].to_s).to eq("Santa/ready/123456")
      expect(hsh[:file_count]).to eq(2)
      expect(hsh[:volume_count]).to eq(0)
    end
  end
end
