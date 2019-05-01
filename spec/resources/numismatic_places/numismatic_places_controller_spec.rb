# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NumismaticPlacesController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        city: "city",
        region: "region"
      }
    end
    let(:invalid_params) do
      {
        title: nil
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "creates a place" do
      FactoryBot.create_for_repository(:numismatic_place)
      post :create, params: { numismatic_place: valid_params }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatic_places"
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_place }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_place }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_place }
      let(:extra_params) { { numismatic_place: { geo_state: "state" } } }
      it_behaves_like "an access controlled update request"
    end
    it "saves and redirects" do
      numismatic_place = FactoryBot.create_for_repository(:numismatic_place)
      patch :update, params: { id: numismatic_place.id.to_s, numismatic_place: { region: "Essex" } }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatic_places"
    end
  end
  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has lists all numismatic places" do
        FactoryBot.create_for_repository(:numismatic_place)

        get :index
        expect(response.body).to have_content "city"
      end
    end
  end
end
