# frozen_string_literal: true
require_relative 'redis_config'
Sidekiq.configure_server do |config|
  config.redis = Redis.current.client.options
end

Sidekiq.configure_client do |config|
  config.redis = Redis.current.client.options
end
