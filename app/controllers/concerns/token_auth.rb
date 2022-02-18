# frozen_string_literal: true

module TokenAuth
  extend ActiveSupport::Concern

  included do
    def current_ability
      Ability.new(current_user, auth_token: params[:auth_token], ip_address: request.remote_ip)
    end
  end
end
