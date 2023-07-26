# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixityDashboardHelper do
  describe "#format_fixity_success_date" do
    it "formats the date as expected" do
      expect(helper.format_fixity_success_date(nil)).to eq "in progress"
      time = Time.current
      expect(helper.format_fixity_success_date(time)).to eq time.strftime("%m/%d/%y %I:%M:%S %p %Z")
    end
  end

  describe "#format_fixity_success" do
    it "translates the nil / 0 / 1 into human-readable text" do
      expect(helper.format_fixity_success(nil)).to eq "In progress"
      expect(helper.format_fixity_success("n/a")).to eq "Not tested yet."
      expect(helper.format_fixity_success(Event::FAILURE)).to eq "Failed"
      expect(helper.format_fixity_success(Event::SUCCESS)).to eq "Successful"
    end
  end

  describe "#format_cloud_fixity_success" do
    it "translates the google status values to match our local labels" do
      expect(helper.format_cloud_fixity_success(nil)).to eq "In progress"
      expect(helper.format_cloud_fixity_success("n/a")).to eq "Not tested yet."
      expect(helper.format_cloud_fixity_success(Event::FAILURE)).to eq "Failed"
      expect(helper.format_cloud_fixity_success(Event::SUCCESS)).to eq "Successful"
    end
  end

  describe "#fixity_success_level" do
    it "translates fixity status label to match bootstrap level" do
      expect(helper.fixity_success_level(nil)).to eq "info"
      expect(helper.fixity_success_level(Event::FAILURE)).to eq "warning"
      expect(helper.fixity_success_level(Event::SUCCESS)).to eq "primary"
    end
  end
end
