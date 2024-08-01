# frozen_string_literal: true
require "json"

# Generates a report of DPUL success metrics given a date range
# This report is used to measure user engagement with DPUL resources
class DpulSuccessDashboardReportGenerator
  attr_reader :date_range

  def initialize(date_range:)
    @date_range = date_range
    @totals_hash = { date: "TOTAL", visitors: 0, pageviews: 0, bounce_rate: 0, visit_duration: 0, visits: 0 }
  end

  def default_dates
    # lux datepicker has a bug with months because it starts January at 0
    # See: https://github.com/pulibrary/lux-design-system/issues/299
    first_day = @date_range.first.prev_month.strftime("%Y,%m,%d")
    last_day = @date_range.last.prev_month.strftime("%Y,%m,%d")
    "start: new Date(" + first_day + "), end: new Date(" + last_day + ")"
  end

  def display_dates
    @date_range.first.strftime("%B %d, %Y") + " - " + @date_range.last.strftime("%B %d, %Y")
  end

  def daily_metrics
    stats_hash = traffic.index_by { |stat| stat["date"] }
    # Iterate over custom event data hashes and merge data into stats
    downloads.each do |date_key, metrics|
      date_str = date_key.to_s
      stats_hash[date_str]&.merge!(metrics.transform_keys(&:to_s))
    end

    record_page_views.each do |date_key, metrics|
      date_str = date_key.to_s
      stats_hash[date_str]&.merge!(metrics.transform_keys(&:to_s))
    end

    viewer_clicks.each do |date_key, metrics|
      date_str = date_key.to_s
      stats_hash[date_str]&.merge!(metrics.transform_keys(&:to_s))
    end

    # Convert stats hash back to array
    stats_with_metrics = stats_hash.values
    stats_with_metrics << @totals_hash.transform_keys(&:to_s)
  end

  def traffic_request
    Faraday.new(url: "https://plausible.io") do |conn|
      conn.request :authorization, "Bearer", Figgy.config["plausible_api_key"]
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
      conn.params["site_id"] = "dpul.princeton.edu"
      conn.params["period"] = "custom"
      conn.params["date"] = @date_range.first.strftime('%Y-%m-%d') + "," + @date_range.last.strftime('%Y-%m-%d')
      conn.params["metrics"] = "visitors,pageviews,bounce_rate,visit_duration,visits"
    end
  end

  def traffic
    response = traffic_request.get("/api/v1/stats/timeseries")
    stats = JSON.parse(response.body)["results"]
    stats.each do |stat|
      @totals_hash[:visitors] += stat["visitors"]
      @totals_hash[:bounce_rate] += stat["bounce_rate"]
      @totals_hash[:pageviews] += stat["pageviews"]
      @totals_hash[:visit_duration] += stat["visit_duration"]
      @totals_hash[:visits] += stat["visits"]
    end
  end

  def downloads_request
    Faraday.new(url: "https://plausible.io") do |conn|
      conn.request :authorization, "Bearer", Figgy.config["plausible_api_key"]
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
      conn.params["site_id"] = "dpul.princeton.edu"
      conn.params["period"] = "custom"
      conn.params["date"] = @date_range.first.strftime('%Y-%m-%d') + "," + @date_range.last.strftime('%Y-%m-%d')
      conn.params["interval"] = "date"
      conn.params["filters"] = "event:goal==Download"
      conn.params["metrics"] = "visitors,events"
    end
  end

  def downloads
    response = downloads_request.get("/api/v1/stats/timeseries")
    downloads_array = JSON.parse(response.body)["results"]
    @totals_hash["download_visitors"] = 0
    @totals_hash["download_events"] = 0
    downloads_array.each_with_object({}) do |download, h|
      h[download["date"].to_sym] = { download_visitors: download["visitors"], download_events: download["events"] }
      @totals_hash["download_visitors"] += download["visitors"]
      @totals_hash["download_events"] += download["events"]
    end
  end

  def record_page_views_request
    Faraday.new(url: "https://plausible.io") do |conn|
      conn.request :authorization, "Bearer", Figgy.config["plausible_api_key"]
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
      conn.params["site_id"] = "dpul.princeton.edu"
      conn.params["period"] = "custom"
      conn.params["date"] = @date_range.first.strftime('%Y-%m-%d') + "," + @date_range.last.strftime('%Y-%m-%d')
      conn.params["interval"] = "date"
      conn.params["filters"] = "event:goal==Visit /*/catalog/*"
      conn.params["metrics"] = "visitors,events"
    end
  end

  def record_page_views
    response = record_page_views_request.get("/api/v1/stats/timeseries")
    rpvs_array = JSON.parse(response.body)["results"]
    @totals_hash["rpv_visitors"] = 0
    @totals_hash["rpv_events"] = 0
    rpvs_array.each_with_object({}) do |rpv, h|
      h[rpv["date"].to_sym] = { rpv_visitors: rpv["visitors"], rpv_events: rpv["events"] }
      @totals_hash["rpv_visitors"] += rpv["visitors"]
      @totals_hash["rpv_events"] += rpv["events"]
    end
  end

  def viewer_clicks_request
    Faraday.new(url: "https://plausible.io") do |conn|
      conn.request :authorization, "Bearer", Figgy.config["plausible_api_key"]
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
      conn.params["site_id"] = "dpul.princeton.edu"
      conn.params["period"] = "custom"
      conn.params["date"] = @date_range.first.strftime('%Y-%m-%d') + "," + @date_range.last.strftime('%Y-%m-%d')
      conn.params["interval"] = "date"
      conn.params["filters"] = "event:goal==UniversalViewer Click"
      conn.params["metrics"] = "visitors,events"
    end
  end

  def viewer_clicks
    response = viewer_clicks_request.get("/api/v1/stats/timeseries")
    viewer_clicks_array = JSON.parse(response.body)["results"]
    @totals_hash["viewer_click_visitors"] = 0
    @totals_hash["viewer_click_events"] = 0
    viewer_clicks_array.each_with_object({}) do |viewer_click, h|
      h[viewer_click["date"].to_sym] = { viewer_click_visitors: viewer_click["visitors"], viewer_click_events: viewer_click["events"] }
      @totals_hash["viewer_click_visitors"] += viewer_click["visitors"]
      @totals_hash["viewer_click_events"] += viewer_click["events"]
    end
  end

  def sources_request
    Faraday.new(url: "https://plausible.io") do |conn|
      conn.request :authorization, "Bearer", Figgy.config["plausible_api_key"]
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
      conn.params["site_id"] = "dpul.princeton.edu"
      conn.params["period"] = "custom"
      conn.params["date"] = @date_range.first.strftime('%Y-%m-%d') + "," + @date_range.last.strftime('%Y-%m-%d')
      conn.params["interval"] = "date"
      conn.params["property"] = "visit:source"
      conn.params["metrics"] = "visitors,bounce_rate"
    end
  end

  def sources
    response = sources_request.get("/api/v1/stats/breakdown")
    JSON.parse(response.body)["results"]
  end
end
