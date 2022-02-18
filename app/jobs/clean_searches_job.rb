# frozen_string_literal: true

class CleanSearchesJob < ApplicationJob
  def perform(days_old: 7)
    logger.info "Cleaning Blacklight searches older than a given number of days"
    Search.delete_old_searches(days_old)
  end
end
