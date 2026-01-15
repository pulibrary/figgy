# frozen_string_literal: true
require "rails_helper"

RSpec.describe HealthReportsController, type: :controller do
  let(:user) { FactoryBot.create(:staff) }

  before do
    sign_in user
  end

  describe "GET #check" do
    it "returns json" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      get :check, params: { id: resource.id, format: :json }
      expect(response).to be_successful

      expect(response.body).to eq(
        {
          status: {
            icon_color: "green",
            label: "Healthy",
            icon: "report-healthy"
          },
          checks: [
            { type: "Local Fixity",
              status: "healthy",
              icon_color: "green",
              label: "Healthy",
              icon: "report-healthy",
              display_unhealthy_resources: false,
              name: "local_fixity",
              unhealthy_resources: [],
              summary: "All local file checksums are verified." },
            { type: "Derivative",
              status: "healthy",
              icon_color: "green",
              label: "Healthy",
              icon: "report-healthy",
              display_unhealthy_resources: false,
              name: "derivative",
              unhealthy_resources: [],
              summary: "Derivatives are processed and healthy." }
          ]
        }.to_json
      )
    end
  end
end
