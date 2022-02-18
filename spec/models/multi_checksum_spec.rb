# frozen_string_literal: true

require "rails_helper"

RSpec.describe MultiChecksum do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:valk_file) do
    Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new("test_id"), io: ::File.open(file, "rb"))
  end
  let(:file2) { fixture_file_upload("files/color-landscape.tif", "image/tiff") }
  let(:valk_file2) do
    Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new("test_id"), io: ::File.open(file2, "rb"))
  end

  describe ".for" do
    it "returns a correct MultiChecksum" do
      mcs = described_class.for(valk_file)
      expect(mcs.md5).to eq "2a28fb702286782b2cbf2ed9a5041ab1"
      expect(mcs.sha1).to eq "1b95e65efc3aefeac1f347218ab6f193328d70f5"
      expect(mcs.sha256).to eq "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c"
    end
  end

  describe ".==" do
    it "returns correct true" do
      mcs1 = described_class.for(valk_file)
      mcs2 = described_class.for(valk_file)
      expect(mcs1.object_id).not_to eq mcs2.object_id
      expect(mcs1).to eq mcs2
    end

    it "returns correct false" do
      mcs1 = described_class.for(valk_file)
      mcs2 = described_class.for(valk_file2)
      expect(mcs1).not_to eq mcs2
    end
  end
end
