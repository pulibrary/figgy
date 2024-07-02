# frozen_string_literal: true
require "rails_helper"

RSpec.describe DPULSuccessDashboardReportGenerator do
  after do
    FileUtils.rm(Rails.root.join("tmp", "output.csv"), force: true)
  end

  context "when given a date range for analytics" do
    it "outputs a CSV with a row per date, and columns for a variety of metrics" do

      report = described_class.new(date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      report.write(path: Rails.root.join("tmp", "output.csv"))
      read = CSV.read(Rails.root.join("tmp", "output.csv"), headers: true, header_converters: :symbol)

      expect(read.length).to eq 1
      first_day = read[0].to_h
      expect(first_day[first_day.keys.first]).to eq DateTime.new(2021, 7, 1)
      expect(first_day[:views_per_visit]).to eq "1"
      expect(first_day[:duration_per_visit]).to eq "1"
    end
  end
end
