# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NumismaticReferencesController, type: :controller do
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
        title: ["Reference 1"],
        short_title: "Ref"
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
    it "creates a reference" do
      FactoryBot.create_for_repository(:numismatic_reference)
      post :create, params: { numismatic_reference: valid_params }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatic_references"
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_reference }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_reference }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_reference }
      let(:extra_params) { { numismatic_reference: { title: ["Reference 2"] } } }
      it_behaves_like "an access controlled update request"
    end
    it "saves and redirects" do
      numismatic_reference = FactoryBot.create_for_repository(:numismatic_reference)
      patch :update, params: { id: numismatic_reference.id.to_s, numismatic_reference: { title: ["Reference 3"] } }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatic_reference"
    end
  end
  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has lists all numismatic references" do
        FactoryBot.create_for_repository(:numismatic_reference)

        get :index
        expect(response.body).to have_content "Test Reference"
      end
    end
  end
end
