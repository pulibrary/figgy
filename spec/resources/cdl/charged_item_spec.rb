# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::ChargedItem do
  describe "#expiration_time" do
    it "returns a time" do
      resource = described_class.new
      resource.expiration_time = Time.zone.at(0)
      expect(resource.expiration_time).to eq Time.zone.at(0)
    end
  end
end
