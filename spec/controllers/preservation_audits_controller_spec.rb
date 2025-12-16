# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationAuditsController, type: :controller do
  describe "GET #index" do
    let(:user) { FactoryBot.create(:admin) }
    before do
      sign_in user if user
    end

    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    context "for non-admin users" do
      let(:user) { FactoryBot.create(:campus_patron) }

      it "prevents viewing" do
        get :index
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #show" do
    let(:audit) { FactoryBot.create(:preservation_audit) }
    let(:user) { FactoryBot.create(:admin) }
    before do
      sign_in user if user
    end

    it "returns http success" do
      get :show, params: { id: audit.id }
      expect(response).to have_http_status(:success)
    end

    context "for non-admin users" do
      let(:user) { FactoryBot.create(:campus_patron) }

      it "prevents viewing" do
        get :show, params: { id: audit.id }
        expect(response).to be_redirect
      end
    end
  end
end
