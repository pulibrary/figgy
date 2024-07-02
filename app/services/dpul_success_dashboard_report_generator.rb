# frozen_string_literal: true
# Generates a report of DPUL success metrics given a date range
# This report is used to measure user engagement with DPUL resources
class DPULSuccessDashboardReportGenerator
  attr_reader :date_range

  def initialize(date_range:)
    @date_range = date_range
  end

  def write(path:)
    CSV.open(path, "w") do |csv|
      csv << headers
      csv_rows.each do |row|
        csv << row
      end
    end
  end

  def to_csv
    CSV.generate do |csv|
      csv << headers
      csv_rows.each do |row|
        csv << row
      end
    end
  end

  def to_h
    CSV.parse(to_csv, headers: true, header_converters: :symbol)
  end

  def headers
    [
      "Date",
      "Views per Visit",
      "Duration per Visit"
    ]
  end

  def plausible_api_request
    # This is the API call we want, code will be modified. The Bearer token (plausible API key) must be sent for success
    # https://plausible.io/api/v1/stats/aggregate?site_id=dpul.princeton.edu&period=custom&date=2024-06-01,2024-07-01&metrics=visitors,pageviews,bounce_rate,visit_duration
  end
end
