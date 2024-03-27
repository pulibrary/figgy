# frozen_string_literal: true
class SmtpStatus < HealthMonitor::Providers::Base
  def check!
    settings = ActionMailer::Base.smtp_settings
    smtp = Net::SMTP.new(settings[:address], settings[:port])
    smtp.open_timeout = 1
    smtp.start
  end
end
