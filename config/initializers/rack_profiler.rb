# frozen_string_literal: true

if Rails.env.development? || Rails.env.staging?
  require "rack-mini-profiler"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.authorization_mode = :allow_authorized
  if Rails.env.staging?
    require "redis"
    config = YAML.safe_load(ERB.new(IO.read(Rails.root.join("config", "redis.yml"))).result, [], [], true)[Rails.env].with_indifferent_access
    Rack::MiniProfiler.config.storage_options = { host: config[:host], port: config[:port], db: config[:db] }
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
  end
end
