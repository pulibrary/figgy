# frozen_string_literal: true

class PreservationAuditMailer < ApplicationMailer
  def success
    @audit = params[:audit]
    mail(to: libanswers,
         subject: "Preservation audit successful")
  end

  def failure
    @audit = params[:audit]
    @failure_count = params[:failure_count]
    mail(to: libanswers,
         subject: "Preservation audit found failures")
  end

  def libanswers
    "digital-library@princeton.libanswers.com"
  end
end
