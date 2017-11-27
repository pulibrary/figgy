# frozen_string_literal: true
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = true
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.log_level = :info
  config.log_tags = [:request_id]
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end
  config.active_record.dump_schema_after_migration = false
  config.middleware.use Rack::Deflater
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=31557600"
  }
  config.action_mailer.default_url_options = { host: ENV.fetch("APPLICATION_HOST", 'localhost'), protocol: ENV.fetch("APPLICATION_HOST_PROTOCOL", "http") }
  config.action_controller.action_on_unpermitted_parameters = false
  config.force_ssl = true
end
