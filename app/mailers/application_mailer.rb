# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: "lsupport@princeton.edu"
  layout "mailer"
end
