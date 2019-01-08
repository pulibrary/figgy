# frozen_string_literal: true
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  helper Openseadragon::OpenseadragonHelper
  layout "application"

  protect_from_forgery with: :exception

  def after_sign_in_path_for(_resource)
    request.env["omniauth.origin"] || root_path
  end

  def guest_uid_authentication_key(key)
    key &&= nil unless key.to_s =~ /^guest/
    return key if key
    "guest_" + guest_user_unique_suffix
  end

  rescue_from Blacklight::AccessControls::AccessDenied, CanCan::AccessDenied, with: :deny_resource_access
  def deny_resource_access(exception)
    respond_to do |format|
      format.json { head :forbidden }
      format.html do
        raise exception if :manifest == exception.action
        if current_user
          redirect_to root_url, alert: exception.message
        else
          redirect_to "/users/auth/cas", alert: exception.message
        end
      end
    end
  end

  # Figgy has no use cases for having unique shared searches, and this prevents
  # the user list from growing out of control.
  def guest_user
    @guest_user ||= User.where(guest: true).first || super
  end
end
