# frozen_string_literal: true
class SmtpStatus < HealthMonitor::Providers::Base
  class << self
    attr_writer :next_check_timestamp

    def next_check_timestamp
      @next_check_timestamp || 0
    end
  end
  def check!
    return unless Time.current > self.class.next_check_timestamp
    settings = ActionMailer::Base.smtp_settings
    tls_setting = settings[:enable_starttls] == false ? false : :auto
    smtp = Net::SMTP.new(settings[:address], settings[:port], starttls: tls_setting)
    smtp.open_timeout = 1
    smtp.start
    self.class.next_check_timestamp = Time.current + 5.minutes
  end
end
