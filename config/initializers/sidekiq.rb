# frozen_string_literal: true
require "redis"

# `Redis.current` is deprecated. We need to establish a connection in
# the same initializer as Sidekiq. See:
# https://github.com/redis/redis-rb/commit/9745e22db65ac294be51ed393b584c0f8b72ae98
redis_config = YAML.safe_load(ERB.new(IO.read(Rails.root.join("config", "redis.yml"))).result, [], [], true)[Rails.env].with_indifferent_access
redis_client = Redis.new(redis_config.merge(thread_safe: true))._client

Sidekiq::Client.reliable_push! unless Rails.env.test?
Sidekiq.configure_server do |config|
  config.redis = redis_client.options
  config.super_fetch!
  config.reliable_scheduler!
end
Sidekiq.configure_client do |config|
  config.redis = redis_client.options
end
