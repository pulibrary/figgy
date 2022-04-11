# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::ReferencesController, type: :controller do
  with_queue_adapter :inline
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }
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
      post :create, params: { numismatics_reference: valid_params }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/references"
      reference = query_service.find_all_of_model(model: Numismatics::Reference).find { |n| n["title"] == ["Reference 1"] }
      expect(reference.depositor).to eq [user.uid]
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
      patch :update, params: { id: numismatic_reference.id.to_s, numismatics_reference: { title: ["Reference 3"] } }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/reference"
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
  describe "index" do
    let(:numismatic_reference) { FactoryBot.create_for_repository(:numismatic_reference, title: "Reference 3") }
    before do
      numismatic_reference
    end
    context "when they have admin permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "lists all numismatic references" do
        get :index
        expect(response.body).to have_content "Reference 3"
      end
    end
    context "when they have staff permission" do
      let(:user) { FactoryBot.create(:staff) }
      render_views
      it "lists all numismatic references" do
        get :index
        expect(response.body).to have_content "Reference 3"
      end
    end
    context "when they are not staff nor admin" do
      let(:user) { FactoryBot.create(:campus_patron) }
      render_views
      it "doesn't list the numismatic references" do
        get :index
        expect(response.body).not_to have_content "References"
        expect(response.body).not_to have_content "Reference 3"
      end
    end
  end
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
