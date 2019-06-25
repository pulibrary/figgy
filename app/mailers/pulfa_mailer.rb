# frozen_string_literal: true
class PulfaMailer < ApplicationMailer
  def branch_notification
    @group = params[:group]
    @url = params[:url]

    email = Figgy.config["pulfa"]["notify_#{params[:group]}"]
    mail(to: email, subject: "SVN Branch For Review") unless email.blank?
  end
end
