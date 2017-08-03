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
end
