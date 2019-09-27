# frozen_string_literal: true
class PulfaMailer < ApplicationMailer
  def branch_notification
    @updated = params[:updated]
    email = Figgy.config["pulfa_notify"]
    mail(to: email, subject: "Figgy DAOs exported to PULFA SVN") unless email.blank?
  end
end
