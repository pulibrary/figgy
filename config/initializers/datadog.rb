# frozen_string_literal: true
Datadog.configure do |c|
  c.tracer(enabled: false) unless Rails.env.production?
  # Rails
  c.use :rails

  # Redis
  c.use :redis

  # Net::HTTP
  c.use :http

  # Sidekiq
  c.use :sidekiq

  # Faraday
  c.use :faraday
end
