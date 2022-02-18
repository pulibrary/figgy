# frozen_string_literal: true

class CleanDeadQueuesJob < ApplicationJob
  def perform
    logger.info "Cleaning the dead Sidekiq Queues"
    Sidekiq::DeadSet.clear
  end
end
