# frozen_string_literal: true

require "rails_helper"

RSpec.describe JP2Creator do
  context "tiff source" do
    it "creates a JP2" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      creator = described_class.new(filename: file.path.to_s)
      output = creator.generate
      image = Vips::Image.new_from_file(output.path.to_s)
      expect(image.width).to eq 200
    end
  end
  context "compressed tiff source" do
    it "creates a JP2" do
      file = fixture_file_upload("files/compressed_example.tif", "image/tiff")
      creator = described_class.new(filename: file.path.to_s)
      output = creator.generate
      image = Vips::Image.new_from_file(output.path.to_s)
      expect(image.width).to eq 200
    end
  end
  context "jpeg source" do
    it "creates a JP2" do
      file = fixture_file_upload("files/large-jpg-test.jpg", "image/jpeg")
      creator = described_class.new(filename: file.path.to_s)
      output = creator.generate
      image = Vips::Image.new_from_file(output.path.to_s)
      expect(image.width).to eq 1867
    end
  end
  context "png source" do
    it "creates a JP2" do
      file = fixture_file_upload("files/abstract.png", "image/png")
      creator = described_class.new(filename: file.path.to_s)
      output = creator.generate
      image = Vips::Image.new_from_file(output.path.to_s)
      expect(image.width).to eq 216
    end
  end
end
