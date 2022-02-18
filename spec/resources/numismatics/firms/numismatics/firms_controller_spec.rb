# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::FirmsController, type: :controller do
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
        city: "city",
        name: "name"
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
    it "creates a firm" do
      FactoryBot.create_for_repository(:numismatic_firm)
      post :create, params: {numismatics_firm: valid_params}
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/firms"
      firm = query_service.find_all_of_model(model: Numismatics::Firm).find { |n| n["city"] == "city" }
      expect(firm.depositor).to eq [user.uid]
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_firm }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_firm }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_firm }
      let(:extra_params) { {numismatics_firm: {city: "city1"}} }
      it_behaves_like "an access controlled update request"
    end
    it "saves and redirects" do
      numismatic_firm = FactoryBot.create_for_repository(:numismatic_firm)
      patch :update, params: {id: numismatic_firm.id.to_s, numismatics_firm: {name: "name"}}
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/firms"
    end
  end
  describe "index" do
    let(:numismatic_firm) { FactoryBot.create_for_repository(:numismatic_firm, city: "Boston") }
    before do
      numismatic_firm
    end
    context "when they have admin permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "lists all numismatic firms" do
        get :index
        expect(response.body).to have_content "Boston"
      end
    end
    context "when they have staff permission" do
      let(:user) { FactoryBot.create(:staff) }
      render_views
      it "lists all numismatic firms" do
        get :index
        expect(response.body).to have_content "Boston"
      end
    end
    context "when they are not staff nor admin" do
      let(:user) { FactoryBot.create(:campus_patron) }
      render_views
      it "doesn't list the numismatic firms" do
        get :index
        expect(response.body).not_to have_content "Numismatic Firms"
        expect(response.body).not_to have_content "Boston"
      end
    end
  end
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
