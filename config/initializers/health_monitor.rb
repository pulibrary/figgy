# frozen_string_literal: true
Rails.application.config.after_initialize do
  HealthMonitor.configure do |config|
    config.cache

    config.add_custom_provider(CheckOverrides::Redis)
    config.add_custom_provider(SolrStatus)
    config.add_custom_provider(AspaceStatus)
    config.add_custom_provider(RabbitMqStatus)
    config.add_custom_provider(SmtpStatus)
    config.add_custom_provider(FileWatcherStatus)
    config.add_custom_provider(IngestMountStatus)

    # monitor all the queues for latency
    # The gem also comes with some additional default monitoring,
    # e.g. it ensures that there are running workers
    config.sidekiq.configure do |sidekiq_config|
      sidekiq_config.latency = 5.days
      sidekiq_config.queue_size = 1_000_000
      sidekiq_config.maximum_amount_of_retries = 17
      sidekiq_config.add_queue_configuration("high", latency: 5.days, queue_size: 1_000_000)
      sidekiq_config.add_queue_configuration("mailers", latency: 5.days, queue_size: 1_000_000)
      sidekiq_config.add_queue_configuration("low", latency: 5.days, queue_size: 1_000_000)
      sidekiq_config.add_queue_configuration("super_low", latency: 5.days, queue_size: 1_000_000)
      sidekiq_config.add_queue_configuration("realtime", latency: 30.seconds, queue_size: 100)
    end

    # Make this health monitor available at /health
    config.path = :health

    config.error_callback = proc do |e|
      Rails.logger.error "Health monitor failed with: #{e.message}"
    end
  end
end
