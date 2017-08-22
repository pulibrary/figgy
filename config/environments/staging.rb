# frozen_string_literal: true
require_relative 'production'

Rails.application.configure do
  config.action_mailer.delivery_method = :sendmail
end
