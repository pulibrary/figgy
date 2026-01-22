require_relative "application"
Datadog.configuration.tracing.log_injection = false
Rails.application.initialize!
