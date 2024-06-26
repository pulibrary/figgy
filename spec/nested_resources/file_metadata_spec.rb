# frozen_string_literal: true
require "rails_helper"

describe FileMetadata do
  subject(:file_metadata) do
    described_class.new(label: label,
                        original_filename: original_filename,
                        mime_type: mime_type,
                        use: use)
  end
  let(:label) { "Test label" }
  let(:original_filename) { "test_file.txt" }
  let(:mime_type) { "application/octet-stream" }
  let(:use) { ::PcdmUse::OriginalFile }

  describe ".for" do
    subject(:file_metadata) { described_class.for(file: file) }

    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    it "constructs an object using File attributes" do
      expect(file_metadata.label).to eq [file.original_filename]
      expect(file_metadata.original_filename).to eq [file.original_filename]
      expect(file_metadata.mime_type).to eq [file.content_type]
      expect(file_metadata.use).to eq [::PcdmUse::OriginalFile]
      expect(file_metadata.created_at).to be_a Time
      expect(file_metadata.updated_at).to be_a Time
      expect(file_metadata.id).to be_a Valkyrie::ID
    end
  end

  describe "#derivative?" do
    let(:use) { ::PcdmUse::ServiceFile }

    it "determines if the FileMetadata is for a derivative file" do
      expect(file_metadata.derivative?).to be true
    end
  end

  describe "#derivative_partial?" do
    let(:use) { ::PcdmUse::ServiceFilePartial }

    it "determines if the FileMetadata is for a part of derivative file" do
      expect(file_metadata.derivative_partial?).to be true
    end
  end

  describe "#original_file?" do
    let(:use) { ::PcdmUse::OriginalFile }

    it "determines if the FileMetadata is for an ingested file" do
      expect(file_metadata.original_file?).to be true
    end

    it "returns true for #preserved?" do
      expect(file_metadata.preserve?).to be true
    end
  end

  describe "thumbnail_file?" do
    let(:use) { ::PcdmUse::ThumbnailImage }

    it "determines if the FileMetadata is for a thumbnail file" do
      expect(file_metadata.thumbnail_file?).to be true
    end

    it "returns false for #preserved?" do
      expect(file_metadata.preserve?).to be false
    end
  end

  describe "preservation_file?" do
    context "when it has the deprecated use value" do
      let(:use) { ::PcdmUse::PreservationMasterFile }

      it "returns true" do
        expect(file_metadata.preservation_file?).to be true
      end
    end

    context "when it has the new preservation use value" do
      let(:use) { ::PcdmUse::PreservationFile }

      it "returns true" do
        expect(file_metadata.preservation_file?).to be true
      end

      it "returns true for #preserved?" do
        expect(file_metadata.preserve?).to be true
      end
    end

    context "when it has the original file use value" do
      it "returns false" do
        expect(file_metadata.preservation_file?).to be false
      end
    end
  end

  describe "preserved_metadata?" do
    let(:use) { ::PcdmUse::PreservedMetadata }

    it "determines if the FileMetadata is for a preservation (BagIt) metadata file" do
      expect(file_metadata.preserved_metadata?).to be true
    end
  end

  describe "preservation_copy?" do
    let(:use) { ::PcdmUse::PreservationCopy }

    it "determines if the FileMetadata if for a copy of a binary for preservation in a (BagIt)" do
      expect(file_metadata.preservation_copy?).to be true
    end

    it "returns true for #preserved?" do
      expect(file_metadata.preserve?).to be true
    end
  end

  describe "intermediate_file?" do
    let(:use) { ::PcdmUse::IntermediateFile }

    it "determines if the FileMetadata is for an intermediate file" do
      expect(file_metadata.intermediate_file?).to be true
    end

    it "returns true for #preserved?" do
      expect(file_metadata.preserve?).to be true
    end
  end

  describe "#cloud_derivative?" do
    let(:use) { ::PcdmUse::CloudDerivative }

    it "determines if the FileMetadata is for a derivative file" do
      expect(file_metadata.cloud_derivative?).to be true
    end

    it "returns false for #preserved?" do
      expect(file_metadata.preserve?).to be false
    end
  end

  describe "#cloud_uri" do
    let(:use) { ::PcdmUse::CloudDerivative }

    context "with a file stored in s3" do
      it "returns the uri" do
        file_metadata.file_identifiers = ["cloud-geo-derivatives-shrine://33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic.json"]
        expect(file_metadata.cloud_uri).to start_with("s3://test-geo/33/1d/70/33")
      end
    end

    context "with a file stored locally" do
      it "returns the uri" do
        file_metadata.file_identifiers = ["disk://tmp/33/1d/70/331d70a54bd94a6580e4763c8f6b34fd/mosaic.json"]
        expect(file_metadata.cloud_uri).to start_with("/tmp/33/1d/70/33")
      end
    end
  end
end
