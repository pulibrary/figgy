# frozen_string_literal: true
class MessagingClient
  class Config < OpenStruct
    def log_level
      value = super
      value = value.constantize if %w[Logger::DEBUG Logger::INFO Logger::WARN Logger::ERROR Logger::FATAL Logger:UNKNOWN].include? value
      value
    end

    def log_file
      value = super
      value = value.constantize if %w[STDIN STDOUT STDERR].include? value
      value
    end
  end

  attr_reader :amqp_url, :config
  def initialize(amqp_url, config: {})
    @amqp_url = amqp_url
    @config = Config.new(config)
  end

  def publish(message)
    exchange.publish(message, persistent: true)
  rescue
    Rails.logger.warn "Unable to publish message to #{amqp_url}"
  end

  private

    def bunny_args
      config.to_h.merge(host: amqp_url)
    end

    def bunny_client
      @bunny_client ||= Bunny.new(*bunny_args).tap(&:start)
    end

    def channel
      @channel ||= bunny_client.create_channel
    end

    def exchange
      @exchange ||= channel.fanout(Figgy.config['events']['exchange']['plum'], durable: true)
    end
end
