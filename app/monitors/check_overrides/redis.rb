class CheckOverrides::Redis < HealthMonitor::Providers::Base
  def check!
    redis.with(&:ping)
  end

  def redis
    ConnectionPool.new(size: 1) { ::Redis.new(RedisConfig.config) }
  end
end
