# frozen_string_literal: true
class SmtpStatus < HealthMonitor::Providers::Base
  def check!
    settings = ActionMailer::Base.smtp_settings
    tls_setting = settings[:enable_starttls] == false ? false : :auto
    smtp = Net::SMTP.new(settings[:address], settings[:port], starttls: tls_setting)
    smtp.open_timeout = 1
    smtp.start
  end
end
