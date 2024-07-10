# frozen_string_literal: true
require "rails_helper"

RSpec.describe DpulSuccessDashboardReportGenerator do

  context "when given a date range for analytics" do

    it "provides a date in human readable format for the date range" do
      report = described_class.new(date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      expect(report.display_dates).to eq "July 01, 2021 - June 30, 2022"
    end

    it "provides a date range that the LUX datepicker can use" do 
      report = described_class.new(date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      expect(report.default_dates).to eq "start: new Date(2021,07,01), end: new Date(2022,06,30)"
    end

    it "retrieves data from plausible and puts it into an array with elements containing metrics for each date" do 
      body = '{
                "results": [
                    {
                        "date": "2024-07-01",
                        "visitors": 0
                    },
                    {
                        "date": "2024-07-02",
                        "visitors": 0
                    },
                    {
                        "date": "2024-07-03",
                        "visitors": 0
                    }
                ]
            }'

      stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2021-07-01T00:00:00%2B00:00,2022-06-30T00:00:00%2B00:00&metrics=visitors,pageviews,bounce_rate,visit_duration,visits&period=custom&site_id=dpul.princeton.edu").
         with(
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Authorization'=>'Bearer plausible_api_key',
       	  'Content-Type'=>'application/json',
       	  'User-Agent'=>'Faraday v2.9.0'
           }).
         to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })
      report = described_class.new(date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      expect(report.plausible_api_request.is_a?(Array)).to be true
      expect(report.plausible_api_request.first['date']).to eq "2024-07-01"
    end

  end
end
