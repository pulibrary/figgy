# frozen_string_literal: true
require_relative "figgy"
Datadog.configure do |c|
  c.tracing.enabled = false unless Rails.env.production?
  c.env = Rails.env.to_s
  c.service = "figgy"
  # Rails
  c.tracing.instrument :rails

  # Redis
  c.tracing.instrument :redis

  # Net::HTTP
  c.tracing.instrument :http

  # Sidekiq
  c.tracing.instrument :sidekiq

  # Faraday
  c.tracing.instrument :faraday

  # Sequel
  c.tracing.instrument :sequel
end
