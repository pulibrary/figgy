# frozen_string_literal: true
require "rails_helper"

# Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
RSpec.describe "CVE-2015-9284", type: :request do
  describe "GET /auth/:provider" do
    it "does not redirect" do
      get "/users/auth/cas"
      expect(response).not_to have_http_status(:redirect)
    end
  end

  describe "POST /auth/:provider without CSRF token" do
    it "raises an error" do
      allow_forgery_protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      expect do
        post "/users/auth/cas"
      end.to raise_error(ActionController::InvalidAuthenticityToken)

      ActionController::Base.allow_forgery_protection = allow_forgery_protection
    end
  end
end
