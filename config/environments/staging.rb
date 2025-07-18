# frozen_string_literal: true
require_relative "production"

Rails.application.configure do
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { address: "lib-ponyexpr-prod.princeton.edu", enable_starttls: false }
  config.action_mailer.default_url_options = { host: ENV.fetch("APPLICATION_HOST", "localhost"), protocol: ENV.fetch("APPLICATION_HOST_PROTOCOL", "http") }
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.active_storage.service = :local
  config.cache_store = :mem_cache_store, "figgy-web-staging1.princeton.edu", { value_max_bytes: 3_000_000 }
  config.action_cable.allowed_request_origins = ["https://figgy-staging.princeton.edu"]
end
