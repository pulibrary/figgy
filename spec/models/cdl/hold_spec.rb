# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::Hold do
  describe "#active?" do
    context "when the expiration_time is set" do
      it "returns true" do
        hold = described_class.new(netid: "miku", expiration_time: Time.current + 1.hour)
        expect(hold).to be_active
      end
    end
    context "when expiration_time is not set" do
      it "returns false" do
        hold = described_class.new(netid: "miku")
        expect(hold).not_to be_active
      end
    end
  end
  describe "#expired?" do
    context "when the expiration_time is in the past" do
      it "returns true" do
        hold = described_class.new(netid: "miku", expiration_time: Time.current - 1.hour)
        expect(hold).to be_expired
      end
    end
    context "when expiration_time is in the future" do
      it "returns false" do
        hold = described_class.new(netid: "miku", expiration_time: Time.current + 1.hour)
        expect(hold).not_to be_expired
      end
    end
  end
end
