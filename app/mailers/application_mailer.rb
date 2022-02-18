# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{Figgy.default_url_options[:host]}"
  layout "mailer"
end
