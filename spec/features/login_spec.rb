# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Logging in" do
  context "when given a login_popup parameter" do
    it "closes the window" do
      user = FactoryBot.create(:admin)
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:cas, uid: user)

      visit user_cas_omniauth_authorize_path(login_popup: "true")

      expect(page.html).to eq "<html><head><script>window.close();</script></head><body></body></html>"
    end
  end
end
