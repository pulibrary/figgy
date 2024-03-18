# frozen_string_literal: true

require "rails_helper"

RSpec.describe Figgy do
  describe ".index_read_only?" do
    context "when configured to be true" do
      it "returns true" do
        allow(described_class.config).to receive(:[]).with("index_read_only").and_return(true)

        expect(described_class.index_read_only?).to eq true
      end
      it "is false in test by default" do
        expect(described_class.index_read_only?).to eq false
      end
    end
  end
end
