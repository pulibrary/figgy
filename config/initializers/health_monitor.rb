# frozen_string_literal: true
Rails.application.config.after_initialize do
  HealthMonitor.configure do |config|
    config.cache
    unless Rails.env.test?
      config.redis.configure do |provider_config|
        provider_config.url = RedisConfig.url
      end
    end

    config.add_custom_provider(SolrStatus)
    config.add_custom_provider(AspaceStatus)

    # Make this health check available at /health
    config.path = :health

    config.error_callback = proc do |e|
      Rails.logger.error "Health check failed with: #{e.message}"
      Honeybadger.notify(e)
    end
  end
end
