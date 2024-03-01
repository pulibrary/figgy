# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "has a health check" do
      stub_aspace_login
      get "/health"
      expect(response).to be_successful
    end
  end
end
