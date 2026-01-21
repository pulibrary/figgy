class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@princeton.edu"
  layout "mailer"
end
