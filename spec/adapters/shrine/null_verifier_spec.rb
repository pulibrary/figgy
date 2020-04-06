# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shrine::NullVerifier do
  describe ".verify_checksum" do
    it "always returns true" do
      expect(described_class.verify_checksum(nil, nil)).to eq true
    end
  end
end
