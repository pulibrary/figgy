# frozen_string_literal: true
require_relative "application"
Datadog.configuration.tracing.log_injection = false
Rails.application.initialize!
