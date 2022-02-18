# frozen_string_literal: true

class CleanGuestUsersJob < ApplicationJob
  def perform(days_old: 7)
    logger.info "Cleaning guest user accounts older than a given number of days"
    User.where("guest = ? and updated_at < ?", true, Time.current - days_old.days).each(&:destroy)
  end
end
