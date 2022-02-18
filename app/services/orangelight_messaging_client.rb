# frozen_string_literal: true

class OrangelightMessagingClient
  attr_reader :amqp_url
  def initialize(amqp_url)
    @amqp_url = amqp_url
  end

  def publish(message)
    exchange.publish(message, persistent: true)
  rescue
    Rails.logger.warn "Unable to publish message to #{amqp_url}"
  end

  private

    def bunny_client
      @bunny_client ||= Bunny.new(amqp_url).tap(&:start)
    end

    def channel
      @channel ||= bunny_client.create_channel
    end

    def exchange
      @exchange ||= channel.fanout(Figgy.config["events"]["exchange"]["orangelight"], durable: true)
    end
end
