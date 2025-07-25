# frozen_string_literal: true
require "rails_helper"

describe Dspace::Bitstream do
  subject(:bitstream) { described_class.new(data) }

  let(:data) do
    {
      "name" => "test-file.pdf"
    }
  end

  describe "#extension" do
    it "returns the file extension" do
      expect(bitstream.extension).to eq ".pdf"
    end
  end

  describe "#name_no_extension" do
    it "returns the file name without the extension" do
      expect(bitstream.name_no_extension).to eq "test-file"
    end
  end
end
