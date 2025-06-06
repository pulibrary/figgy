# frozen_string_literal: true
Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=3600"
  }
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test
  config.active_support.deprecation = :stderr
  config.i18n.raise_on_missing_translations = true
  config.action_view.cache_template_loading = true
  config.assets.raise_runtime_errors = true
  config.action_mailer.default_url_options = { host: "www.example.com" }
  config.active_job.queue_adapter = :test
  config.action_controller.action_on_unpermitted_parameters = false
  config.active_storage.service = :test
  config.cache_store = :null_store
  # Mocking login only works with lax cookies.
  config.action_dispatch.cookies_same_site_protection = :lax
  config.active_record.dump_schema_after_migration = false
end
