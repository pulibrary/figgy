# frozen_string_literal: true
Rails.application.configure do
  config.action_dispatch.cookies_same_site_protection = :none
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = true
  config.assets.compile = false
  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.active_record.dump_schema_after_migration = false
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=31557600"
  }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { address: "lib-ponyexpr.princeton.edu" }
  config.action_mailer.default_url_options = { host: ENV.fetch("APPLICATION_HOST", "localhost"), protocol: ENV.fetch("APPLICATION_HOST_PROTOCOL", "http") }
  config.action_mailer.perform_caching = false
  config.action_controller.action_on_unpermitted_parameters = false
  config.force_ssl = false
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
  config.active_storage.service = :local
  config.cache_store = :mem_cache_store, "figgy1.princeton.edu"
end
