# frozen_string_literal: true

module CDL
  class HoldMailer < ApplicationMailer
    layout "holds/mailer"
    def hold_activated
      @user = params[:user]
      @resource = query_service.find_by(id: params[:resource_id])
      mail(to: @user.email, subject: "Available for Digital Checkout: #{@resource.decorate.first_title}")
    end

    def hold_expired
      @user = params[:user]
      @resource = query_service.find_by(id: params[:resource_id])
      mail(to: @user.email, subject: "Digital Checkout Reservation Expired: #{@resource.decorate.first_title}")
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
  end
end
