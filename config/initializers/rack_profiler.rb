if Rails.env.development? || Rails.env.staging?
  require "rack-mini-profiler"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.authorization_mode = :allow_authorized
  if Rails.env.staging?
    require "redis"
    require_relative "redis_config"
    Rack::MiniProfiler.config.storage_options = RedisConfig.config
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
  end
end
