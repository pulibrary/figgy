require 'json'

# frozen_string_literal: true
# Generates a report of DPUL success metrics given a date range
# This report is used to measure user engagement with DPUL resources
class DpulSuccessDashboardReportGenerator
  attr_reader :date_range

  def initialize(date_range:)
    @date_range = date_range
  end

  def date_range 
    @date_range
  end

  def default_dates 
    first_day = @date_range.first.strftime('%Y,%m,%d')
    last_day = @date_range.last.strftime('%Y,%m,%d')
    'start: new Date(' + first_day + '), end: new Date(' + last_day + ')'
  end

  def display_dates
    @date_range.first.strftime('%B %d, %Y') + ' - ' + @date_range.last.strftime('%B %d, %Y')
  end

  def daily_metrics
      # Convert traffic stats array to a hash with date as key for easier lookup
      stats_hash = traffic.index_by { |stat| stat["date"] }

      downloads_hash = downloads.each_with_object({}) do |download, h| 
        h[download['date'].to_sym] = { download_visitors: download['visitors'], download_events: download['events'] } 
      end

      # Iterate over downloads_hash and merge data into stats
      downloads_hash.each do |date_key, metrics|
        date_str = date_key.to_s # Convert symbol key to string

        if stats_hash[date_str]
          # Merge downloads into corresponding stats element
          stats_hash[date_str].merge!(metrics.transform_keys(&:to_s))
        end
      end

      rpvs_hash = record_page_views.each_with_object({}) do |rpv, h| 
        h[rpv['date'].to_sym] = { rpv_visitors: rpv['visitors'], rpv_events: rpv['events'] } 
      end

      # Iterate over rpvs_hash and merge data into stats
      rpvs_hash.each do |date_key, metrics|
        date_str = date_key.to_s # Convert symbol key to string

        if stats_hash[date_str]
          # Merge rpvs into corresponding stats element
          stats_hash[date_str].merge!(metrics.transform_keys(&:to_s))
        end
      end

      vc_hash = viewer_clicks.each_with_object({}) do |viewer_click, h| 
        h[viewer_click['date'].to_sym] = { viewer_click_visitors: viewer_click['visitors'], viewer_click_events: viewer_click['events'] } 
      end

      # Iterate over viewer_clicks hash and merge data into stats
      vc_hash.each do |date_key, metrics|
        date_str = date_key.to_s # Convert symbol key to string

        if stats_hash[date_str]
          # Merge downloads into corresponding stats element
          stats_hash[date_str].merge!(metrics.transform_keys(&:to_s))
        end
      end

      # Convert stats hash back to array
      stats_with_metrics = stats_hash.values
  end

  def traffic
      request = Faraday.new(url: 'https://plausible.io') do |conn|
        # Need help
        conn.request :authorization, 'Bearer', Figgy.config["plausible_api_key"]
        conn.adapter Faraday.default_adapter
        conn.headers['Content-Type'] = 'application/json'
        conn.params['site_id'] = 'dpul.princeton.edu'
        conn.params['period'] = 'custom'
        conn.params['date'] = @date_range.first.iso8601 + ',' + @date_range.last.iso8601
        conn.params['metrics'] = 'visitors,pageviews,bounce_rate,visit_duration,visits'
      end
        response = request.get("/api/v1/stats/timeseries")
        stats = JSON.parse(response.body)['results']
  end

  def downloads
      request = Faraday.new(url: 'https://plausible.io') do |conn|
        conn.request :authorization, 'Bearer', Figgy.config["plausible_api_key"]
        conn.adapter Faraday.default_adapter
        conn.headers['Content-Type'] = 'application/json'
        conn.params['site_id'] = 'dpul.princeton.edu'
        conn.params['period'] = 'custom'
        conn.params['date'] = @date_range.first.iso8601 + ',' + @date_range.last.iso8601
        conn.params['interval'] = 'date'
        conn.params['filters'] = 'event:goal==Download'
        conn.params['metrics'] = 'visitors,events'
      end
      response = request.get("/api/v1/stats/timeseries")
      downloads_array = JSON.parse(response.body)['results']
  end 

  def record_page_views 
      request = Faraday.new(url: 'https://plausible.io') do |conn|
        conn.request :authorization, 'Bearer', Figgy.config["plausible_api_key"]
        conn.adapter Faraday.default_adapter
        conn.headers['Content-Type'] = 'application/json'
        conn.params['site_id'] = 'dpul.princeton.edu'
        conn.params['period'] = 'custom'
        conn.params['date'] = @date_range.first.iso8601 + ',' + @date_range.last.iso8601
        conn.params['interval'] = 'date'
        conn.params['filters'] = 'event:goal==Visit /*/catalog/*'
        conn.params['metrics'] = 'visitors,events'
      end

      response = request.get("/api/v1/stats/timeseries")
      rpvs_array = JSON.parse(response.body)['results']
  end 

  def viewer_clicks
      request = Faraday.new(url: 'https://plausible.io') do |conn|
        conn.request :authorization, 'Bearer', Figgy.config["plausible_api_key"]
        conn.adapter Faraday.default_adapter
        conn.headers['Content-Type'] = 'application/json'
        conn.params['site_id'] = 'dpul.princeton.edu'
        conn.params['period'] = 'custom'
        conn.params['date'] = @date_range.first.iso8601 + ',' + @date_range.last.iso8601
        conn.params['interval'] = 'date'
        conn.params['filters'] = 'event:goal==UniversalViewer Click'
        conn.params['metrics'] = 'visitors,events'
      end

      response = request.get("/api/v1/stats/timeseries")
      viewer_clicks_array = JSON.parse(response.body)['results']
  end 

  def sources
    request = Faraday.new(url: 'https://plausible.io') do |conn|
      conn.request :authorization, 'Bearer', Figgy.config["plausible_api_key"]
      conn.adapter Faraday.default_adapter
      conn.headers['Content-Type'] = 'application/json'
      conn.params['site_id'] = 'dpul.princeton.edu'
      conn.params['period'] = 'custom'
      conn.params['date'] = @date_range.first.iso8601 + ',' + @date_range.last.iso8601
      conn.params['interval'] = 'date'
      conn.params['property'] = 'visit:source'
      conn.params['metrics'] = 'visitors,bounce_rate'
    end
    response = request.get("/api/v1/stats/breakdown")
    sources = JSON.parse(response.body)['results']
  end 

end
