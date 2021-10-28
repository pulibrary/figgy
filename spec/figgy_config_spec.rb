# frozen_string_literal: true

require "rails_helper"

RSpec.describe Figgy do
  describe ".index_read_only?" do
    it "defaults false" do
      expect(described_class.index_read_only?).to eq false
    end

    context "when set via env" do
      it "can be true" do
        allow(ENV).to receive(:fetch).with("INDEX_READ_ONLY", false).and_return("true")
        expect(described_class.index_read_only?).to eq true
      end
    end
  end
end
