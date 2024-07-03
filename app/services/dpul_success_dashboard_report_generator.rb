require 'json'
# frozen_string_literal: true
# Generates a report of DPUL success metrics given a date range
# This report is used to measure user engagement with DPUL resources
class DpulSuccessDashboardReportGenerator
  attr_reader :date_range

  def initialize(date_range:)
    @date_range = date_range
  end

  def plausible_api_request
    # This is the API call we want, code will be modified. The Bearer token (plausible API key) must be sent for success
    # https://plausible.io/api/v1/stats/aggregate?site_id=dpul.princeton.edu&period=custom&date=2024-06-01,2024-07-01&metrics=visitors,pageviews,bounce_rate,visit_duration
    # Figgy.config["plausible_api_key"]
    
    request = Faraday.new(url: 'https://plausible.io') do |conn|
      # Need help
      #conn.request :authorization, 'Bearer', '#{Figgy.config["plausible_api_key"]}'
      conn.adapter Faraday.default_adapter
      conn.headers['Content-Type'] = 'application/json'
      conn.params['site_id'] = 'dpul.princeton.edu'
      conn.params['period'] = 'month'
      #conn.params['date'] = @date_range.first.strftime("%Y/%m/%d") + ',' + @date_range.last.strftime("%Y/%m/%d")
      conn.params['metrics'] = 'visitors,pageviews,bounce_rate,visit_duration'
    end
    response = request.get("/api/v1/stats/aggregate")
    #response = request.get("/api/v1/stats/aggregate?site_id=dpul.princeton.edu&period=custom&date=2024-06-01,2024-07-01&metrics=visitors,pageviews,bounce_rate,visit_duration")
    stats = JSON.parse(response.body).first.last
  end
end
