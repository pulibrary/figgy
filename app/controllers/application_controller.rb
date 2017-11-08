# frozen_string_literal: true
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  helper Openseadragon::OpenseadragonHelper
  layout 'application'

  protect_from_forgery with: :exception

  def guest_uid_authentication_key(key)
    key &&= nil unless key.to_s =~ /^guest/
    return key if key
    "guest_" + guest_user_unique_suffix
  end

  # use it in a subclass like:
  #   rescue_from CanCan::AccessDenied, with: :deny_resource_access
  def deny_resource_access(exception)
    respond_to do |format|
      format.json { head :forbidden }
      format.html do
        raise exception if :manifest == exception.action
        if current_user
          redirect_to root_url, alert: exception.message
        else
          redirect_to '/users/auth/cas', alert: exception.message
        end
      end
    end
  end
end
