# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::PlacesController, type: :controller do
  with_queue_adapter :inline
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }
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
        city: "Seattle",
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
      post :create, params: { numismatics_place: valid_params }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/places"
      place = query_service.find_all_of_model(model: Numismatics::Place).find { |n| n["city"] == "Seattle" }
      expect(place.depositor).to eq [user.uid]
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
      patch :update, params: { id: numismatic_place.id.to_s, numismatics_place: { region: "Essex" } }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/places"
    end
  end
  describe "index" do
    let(:numismatic_place) { FactoryBot.create_for_repository(:numismatic_place, city: "Athens") }
    before do
      numismatic_place
    end
    context "when they have admin permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "lists all numismatic places" do
        get :index
        expect(response.body).to have_content "Athens"
      end
    end
    context "when they have staff permission" do
      let(:user) { FactoryBot.create(:staff) }
      render_views
      it "lists all numismatic places" do
        get :index
        expect(response.body).to have_content "Athens"
      end
    end
    context "when they are not staff nor admin" do
      let(:user) { FactoryBot.create(:campus_patron) }
      render_views
      it "doesn't list the numismatic places" do
        get :index
        expect(response.body).not_to have_content "Places"
        expect(response.body).not_to have_content "Athens"
      end
    end
  end
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
