# frozen_string_literal: true

# We have a maintenance window every Monday for Staging and Tuesday for
# production, from 5:30 AM to 8:30 AM.
class HoneybadgerCheck
  def self.maintenance_window?
    return false unless Rails.env.staging? || Rails.env.production?
    # Check in Eastern time.
    Time.use_zone("America/New_York") do
      current_time = Time.zone.now
      # Only check times if we're the correct day of the week.
      return false if Rails.env.staging? && !current_time.monday?
      return false if Rails.env.production? && !current_time.tuesday?
      current_time.between?(Time.zone.parse("5:30"), Time.zone.parse("8:30"))
    end
  end
end
Honeybadger.configure do |config|
  config.before_notify do |notice|
    # Add a maintenance_window tag - tags seems to be a comma delimited string,
    # so split them, add the maintenance_window one, and rejoin them.
    notice.context[:maintenance_window] = "true" if HoneybadgerCheck.maintenance_window?
  end
end
