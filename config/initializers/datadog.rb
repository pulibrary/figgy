# frozen_string_literal: true
if Rails.env.production?
  require 'ddtrace'
  Datadog.configure do |c|
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
end
