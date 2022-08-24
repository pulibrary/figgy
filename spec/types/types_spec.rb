# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types do
  describe "DateEastern" do
    it "casts a M/D/YYYY string to a date in eastern time zone at midnight" do
      date_eastern = ::Types::DateEastern.call("1/27/2025")
      expect(date_eastern).to be_a ActiveSupport::TimeWithZone
      expect(date_eastern.time_zone.name).to eq "Eastern Time (US & Canada)"
      expect(date_eastern.hour).to eq 0
      expect(date_eastern.min).to eq 0
      expect(date_eastern.sec).to eq 0
    end

    it "errors if given a YYYY/M/D string" do
      expect { ::Types::DateEastern.call("2025/1/27") }.to raise_error(Types::CoercionError)
    end
  end
end
