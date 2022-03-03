# frozen_string_literal: true
class PulmapPublishingJob < ApplicationJob
  queue_as :high

  def perform(message)
    GeoblacklightEventProcessor.new(message).process
  end
end
