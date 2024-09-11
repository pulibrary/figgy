# frozen_string_literal: true

class CheckOverrides::Redis < HealthMonitor::Providers::Base
  def check!
    redis.with(&:ping)
  end

  def redis
    ConnectionPool.new(size: 1) { ::Redis.new(url: RedisConfig.url) }
  end
end
