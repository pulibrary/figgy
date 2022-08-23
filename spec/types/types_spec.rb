# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types do
  describe "DateEastern" do
    context "when input is a string" do
      it "casts a M/D/YYYY string to a date in eastern time zone at midnight" do
        date_eastern = Types::DateEastern.call("1/27/2025")
        expect(date_eastern).to be_a ActiveSupport::TimeWithZone
        expect(date_eastern.time_zone.name).to eq "Eastern Time (US & Canada)"
        expect(date_eastern.hour).to eq 0
        expect(date_eastern.min).to eq 0
        expect(date_eastern.sec).to eq 0
      end

      it "errors if given a YYYY/M/D string" do
        expect { Types::DateEastern.call("2025/1/27") }.to raise_error(Types::CoercionError)
      end
    end
  end

  context "when input is a TimeWithZone" do
    it "accepts a Time object if it's in eastern time zone already" do
      time = Time.zone.now.in_time_zone("Eastern Time (US & Canada)")
      date_eastern = Types::DateEastern.call(time)
      expect(date_eastern).to be_a ActiveSupport::TimeWithZone
    end

    it "errors if it's not in the eastern time zone" do
      time = Time.zone.now
      expect { Types::DateEastern.call(time) }.to raise_error(Types::CoercionError)
    end
  end

  context "when input is a DateTime" do
    it "coerces it if it's in eastern time zone already" do
      time = Time.zone.now.in_time_zone("Eastern Time (US & Canada)")
      date_time = DateTime.parse(time.to_s)
      date_eastern = Types::DateEastern.call(date_time)
      expect(date_eastern).to be_a ActiveSupport::TimeWithZone
    end
  end
end
