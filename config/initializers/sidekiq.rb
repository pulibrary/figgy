# frozen_string_literal: true
require_relative "redis_config"

# `Redis.current` is deprecated. We need to establish a connection in
# the same initializer as Sidekiq. See:
# https://github.com/redis/redis-rb/commit/9745e22db65ac294be51ed393b584c0f8b72ae98
Sidekiq::Client.reliable_push! unless Rails.env.test?
Sidekiq.configure_server do |config|
  config.redis = { url:  RedisConfig.url }
  config.super_fetch!
  config.reliable_scheduler!
end
Sidekiq.configure_client do |config|
  config.redis = { url:  RedisConfig.url }
end
