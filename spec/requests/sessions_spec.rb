# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions" do
  context "when logging out" do
    let(:user) { FactoryBot.create(:admin) }

    before do
      sign_in user
    end

    it "redirects to the CAS logout page" do
      get destroy_user_session_path
      expect(response).to redirect_to(Rails.configuration.x.after_sign_out_url)
    end
  end
end
