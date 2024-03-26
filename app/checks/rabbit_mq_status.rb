# frozen_string_literal: true
class RabbitMqStatus < HealthMonitor::Providers::Base
  def check!
    Figgy.messaging_client.bunny_client
  end
end
