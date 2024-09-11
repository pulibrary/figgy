# frozen_string_literal: true
class AspaceStatus < HealthMonitor::Providers::Base
  def check!
    Aspace::Client.new
  end
end
