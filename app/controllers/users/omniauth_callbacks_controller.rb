# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if request.env["omniauth.params"].present? && request.env["omniauth.params"]["login_popup"].present?
      sign_in @user, event: :authentication
      render inline: "<html><head><script>window.close();</script></head><body></body></html>".html_safe
    else
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "CAS") if is_navigational_format?
    end
  end
end
