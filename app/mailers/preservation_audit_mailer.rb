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

  def complete
    @audit = params[:audit]
    mail(to: libanswers,
         subject: "Preservation audit: all jobs have run once")
  end

  def dead
    @audit = params[:audit]
    mail(to: libanswers,
         subject: "Preservation audit: dead queue")
  end

  def libanswers
    "digital-library@princeton.libanswers.com"
  end
end
