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

    it "retrieves traffic data from plausible and puts it into an array of objects containing metrics for each date" do 
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
      expect(report.traffic.is_a?(Array)).to be true
      expect(report.traffic.first['date']).to eq "2024-07-01"
    end

    it "retrieves the number of downloads in the given date range from plausible and puts it into an array of objects containing the number of downloads for each date" do 
      # Does this tally the number of visitors who achieved this "goal"? Or does it tally the number of times the goal was achieved? We should verify this.
      # Verify if there is any latency in the numbers. For example, if I download an item, the expectation is that the api data would reflect that immediately.
      body = '{
            "results": [
                {
                    "date": "2024-07-01",
                    "visitors": 3
                },
                {
                    "date": "2024-07-02",
                    "visitors": 5
                },
                {
                    "date": "2024-07-03",
                    "visitors": 10
                }
            ]
        }'

      stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&filters=event:goal==Download&interval=date&period=custom&site_id=dpul.princeton.edu&metrics=visitors,events").
         with(
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Authorization'=>'Bearer plausible_api_key',
       	  'Content-Type'=>'application/json',
       	  'User-Agent'=>'Faraday v2.9.0'
           }).
         to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 03))
      expect(report.downloads.is_a?(Array)).to be true
      expect(report.downloads.first['date']).to eq "2024-07-01"
    end

    it "retrieves the number of viewer clicks in the given date range from plausible and puts it into an array of objects containing the number of viewer clicks for each date" do 
      body = '{
        "results": [
            {
                "date": "2024-07-01",
                "visitors": 3
            },
            {
                "date": "2024-07-02",
                "visitors": 5
            },
            {
                "date": "2024-07-03",
                "visitors": 10
            }
        ]
      }'

      stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&filters=event:goal==UniversalViewer%2520Click&interval=date&metrics=visitors,events&period=custom&site_id=dpul.princeton.edu").
         with(
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Authorization'=>'Bearer plausible_api_key',
       	  'Content-Type'=>'application/json',
       	  'User-Agent'=>'Faraday v2.9.0'
           }).
         to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 03))
      expect(report.viewer_clicks.is_a?(Array)).to be true
      expect(report.viewer_clicks.first['date']).to eq "2024-07-01"
    end

    it "retrieves the number of record page views in the given date range from plausible and puts it into an array of objects containing the number of RPVs for each date" do 
      body = '{
            "results": [
                {
                    "date": "2024-07-01",
                    "visitors": 3
                },
                {
                    "date": "2024-07-02",
                    "visitors": 5
                },
                {
                    "date": "2024-07-03",
                    "visitors": 10
                }
            ]
        }'

      stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&filters=event:goal==Visit%2520/*/catalog/*&interval=date&metrics=visitors,events&period=custom&site_id=dpul.princeton.edu").
         with(
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Authorization'=>'Bearer plausible_api_key',
       	  'Content-Type'=>'application/json',
       	  'User-Agent'=>'Faraday v2.9.0'
           }).
         to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 03))
      expect(report.record_page_views.is_a?(Array)).to be true
      expect(report.record_page_views.first['date']).to eq "2024-07-01"
    end

    it "retrieves the number of unique traffic sources in the given date range from plausible and puts it into an array of objects containing the number of unique sources for each date" do 
      body = '{
            "results": [
                {
                    "date": "2024-07-01",
                    "visitors": 3
                },
                {
                    "date": "2024-07-02",
                    "visitors": 5
                },
                {
                    "date": "2024-07-03",
                    "visitors": 10
                }
            ]
        }'

      stub_request(:get, "https://plausible.io/api/v1/stats/breakdown?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&interval=date&metrics=visitors,bounce_rate&period=custom&property=visit:source&site_id=dpul.princeton.edu").
         with(
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Authorization'=>'Bearer plausible_api_key',
       	  'Content-Type'=>'application/json',
       	  'User-Agent'=>'Faraday v2.9.0'
           }).
         to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 03))
      expect(report.sources.is_a?(Array)).to be true
      expect(report.sources.first['date']).to eq "2024-07-01"
    end

  end
end
