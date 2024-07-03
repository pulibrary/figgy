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
    request = Faraday.new(url: 'https://plausible.io') do |conn|
      # Need help
      conn.request :authorization, 'Bearer', Figgy.config["plausible_api_key"]
      conn.adapter Faraday.default_adapter
      conn.headers['Content-Type'] = 'application/json'
      conn.params['site_id'] = 'dpul.princeton.edu'
      conn.params['period'] = 'custom'
      conn.params['date'] = @date_range.first.strftime("%Y-%m-%d") + ',' + @date_range.last.iso8601
      conn.params['metrics'] = 'visitors,pageviews,bounce_rate,visit_duration'
    end
    response = request.get("/api/v1/stats/aggregate")
    stats = JSON.parse(response.body).first.last
  end
end
