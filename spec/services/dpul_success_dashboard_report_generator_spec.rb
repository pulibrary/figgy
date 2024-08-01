# frozen_string_literal: true
require "rails_helper"

RSpec.describe DpulSuccessDashboardReportGenerator do
  before do
    body = '{
              "results": [
                  {
                      "date": "2024-07-01",
                      "visitors": 3,
                      "events": 4,
                      "bounce_rate": 4,
                      "pageviews": 4,
                      "visits": 4,
                      "visit_duration": 4
                  },
                  {
                      "date": "2024-07-02",
                      "visitors": 5,
                      "events": 10,
                      "bounce_rate": 4,
                      "pageviews": 4,
                      "visits": 4,
                      "visit_duration": 4
                  },
                  {
                      "date": "2024-07-03",
                      "visitors": 7,
                      "events": 3,
                      "bounce_rate": 4,
                      "pageviews": 4,
                      "visits": 4,
                      "visit_duration": 4
                  }
              ]
            }'

    stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2021-07-01T00:00:00%2B00:00,2022-06-30T00:00:00%2B00:00&metrics=visitors,pageviews,bounce_rate,visit_duration,visits&period=custom&site_id=dpul.princeton.edu")
      .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer plausible_api_key",
            "Content-Type" => "application/json",
            "User-Agent" => "Faraday v2.9.0"
          }
        ).to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })

    stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&filters=event:goal==Download&interval=date&metrics=visitors,events&period=custom&site_id=dpul.princeton.edu")
      .with(
         headers: {
           "Accept" => "*/*",
           "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
           "Authorization" => "Bearer plausible_api_key",
           "Content-Type" => "application/json",
           "User-Agent" => "Faraday v2.9.0"
         }
       )
      .to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })

    stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&filters=event:goal==UniversalViewer%20Click&interval=date&metrics=visitors,events&period=custom&site_id=dpul.princeton.edu")
      .with(
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Authorization" => "Bearer plausible_api_key",
                "Content-Type" => "application/json",
                "User-Agent" => "Faraday v2.9.0"
              }
            )
      .to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })

    stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&filters=event:goal==Visit%20/*/catalog/*&interval=date&metrics=visitors,events&period=custom&site_id=dpul.princeton.edu")
      .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Authorization" => "Bearer plausible_api_key",
              "Content-Type" => "application/json",
              "User-Agent" => "Faraday v2.9.0"
            }
          )
      .to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })
  end

  context "when given a date range for analytics" do
    it "provides a date in human readable format for the date range" do
      report = described_class.new(date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      expect(report.display_dates).to eq "July 01, 2021 - June 30, 2022"
    end

    it "provides a date range that the LUX datepicker can use" do
      report = described_class.new(date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      # The discrepency in months is due to a workaround to a LUX datepicker bug. 
      # See: https://github.com/pulibrary/lux-design-system/issues/299
      expect(report.default_dates).to eq "start: new Date(2021,06,01), end: new Date(2022,05,30)"
    end

    it "retrieves traffic data from plausible and puts it into an array of objects containing metrics for each date" do
      report = described_class.new(date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      expect(report.traffic.is_a?(Array)).to be true
      expect(report.traffic.first["date"]).to eq "2024-07-01"
    end

    it "retrieves the number of downloads in the given date range from plausible and puts it into an array of objects containing the number of downloads for each date" do
      # Does this tally the number of visitors who achieved this "goal"? Or does it tally the number of times the goal was achieved? We should verify this.
      # Verify if there is any latency in the numbers. For example, if I download an item, the expectation is that the api data would reflect that immediately.
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 3))
      expect(report.downloads.is_a?(Hash)).to be true
      expect(report.downloads.key?(:"2024-07-01")).to be true
    end

    it "retrieves the number of viewer clicks in the given date range from plausible and puts it into an array of objects containing the number of viewer clicks for each date" do
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 3))
      expect(report.viewer_clicks.is_a?(Hash)).to be true
      expect(report.viewer_clicks.key?(:"2024-07-01")).to be true
    end

    it "retrieves the number of record page views in the given date range from plausible and puts it into an array of objects containing the number of RPVs for each date" do
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 3))
      expect(report.record_page_views.is_a?(Hash)).to be true
      expect(report.record_page_views.key?(:"2024-07-01")).to be true
    end

    it "retrieves the number of unique traffic sources in the given date range from plausible and puts it into an array of objects containing the number of unique sources for each date" do
      body = '{
            "results": [
                {
                    "date": "2024-07-01",
                    "visitors": 3,
                    "events": 4
                },
                {
                    "date": "2024-07-02",
                    "visitors": 3,
                    "events": 4
                },
                {
                    "date": "2024-07-03",
                    "visitors": 3,
                    "events": 4
                }
            ]
        }'

      stub_request(:get, "https://plausible.io/api/v1/stats/breakdown?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&interval=date&metrics=visitors,bounce_rate&period=custom&property=visit:source&site_id=dpul.princeton.edu")
        .with(
           headers: {
             "Authorization" => "Bearer plausible_api_key",
             "Content-Type" => "application/json",
             "User-Agent" => "Faraday v2.9.0"
           }
         ).to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })
      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 3))
      expect(report.sources.is_a?(Array)).to be true
      expect(report.sources.first["date"]).to eq "2024-07-01"
    end

    it "retrieves an aggregate of general and custom event metrics from plausible for each date in the given range" do
      body = '{
                "results": [
                    {
                        "date": "2024-07-01",
                        "visitors": 5,
                        "bounce_rate": 4,
                        "pageviews": 4,
                        "visits": 4,
                        "visit_duration": 4
                    },
                    {
                        "date": "2024-07-02",
                        "visitors": 5,
                        "bounce_rate": 4,
                        "pageviews": 4,
                        "visits": 4,
                        "visit_duration": 4
                    },
                    {
                        "date": "2024-07-03",
                        "visitors": 5,
                        "bounce_rate": 4,
                        "pageviews": 4,
                        "visits": 4,
                        "visit_duration": 4
                    }
                ]
              }'

      stub_request(:get, "https://plausible.io/api/v1/stats/timeseries?date=2024-07-01T00:00:00%2B00:00,2024-07-03T00:00:00%2B00:00&metrics=visitors,pageviews,bounce_rate,visit_duration,visits&period=custom&site_id=dpul.princeton.edu")
        .with(
           headers: {
             "Accept" => "*/*",
             "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
             "Authorization" => "Bearer plausible_api_key",
             "Content-Type" => "application/json",
             "User-Agent" => "Faraday v2.9.0"
           }
         ).to_return(status: 200, body: body, headers: { "Content-Type": "application/json" })

      report = described_class.new(date_range: DateTime.new(2024, 7, 1)..DateTime.new(2024, 7, 3))
      metrics = report.daily_metrics
      expect(metrics.is_a?(Array)).to be true
      expect(metrics.first["date"]).to eq "2024-07-01"
      expect(metrics.first["bounce_rate"]).to eq 4
      expect(metrics.first["download_events"]).to eq 4
      expect(metrics.first["download_visitors"]).to eq 3
      expect(metrics.first["rpv_events"]).to eq 4
      expect(metrics.first["rpv_visitors"]).to eq 3
      expect(metrics.first["viewer_click_events"]).to eq 4
      expect(metrics.first["viewer_click_visitors"]).to eq 3
      expect(metrics.last["download_visitors"]).to eq 15
      expect(metrics.last["bounce_rate"]).to eq 12
    end
  end
end
