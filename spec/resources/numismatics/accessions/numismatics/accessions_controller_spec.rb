# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::AccessionsController, type: :controller do
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
        date: ["01/02/2003"],
        cost: "$123.00"
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
    it "creates an accession" do
      FactoryBot.create_for_repository(:numismatic_accession)
      post :create, params: {numismatics_accession: valid_params}
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/accessions"
      accession = query_service.find_all_of_model(model: Numismatics::Accession).find { |n| n["cost"] == ["$123.00"] }
      expect(accession.depositor).to eq [user.uid]
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_accession }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_accession }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_accession }
      let(:extra_params) { {numismatic_accession: {type: ["gift"]}} }
      it_behaves_like "an access controlled update request"
    end
    it "saves and redirects" do
      numismatic_accession = FactoryBot.create_for_repository(:numismatic_accession)
      patch :update, params: {id: numismatic_accession.id.to_s, numismatics_accession: {type: ["super gift"]}}
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/accessions"
    end
  end
  describe "index" do
    let(:numismatic_accession) { FactoryBot.create_for_repository(:numismatic_accession, accession_number: 123_123_123_123_123) }
    before do
      numismatic_accession
    end
    context "when they have admin permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "lists all numismatic accessions" do
        get :index
        expect(response.body).to have_content "123123123123123"
      end
    end
    context "when they have staff permission" do
      let(:user) { FactoryBot.create(:staff) }
      render_views
      it "lists all numismatic accessions" do
        get :index
        expect(response.body).to have_content "123123123123123"
      end
    end
    context "when they are not staff nor admin" do
      let(:user) { FactoryBot.create(:campus_patron) }
      render_views
      it "doesn't list the numismatic accessions" do
        get :index
        expect(response.body).not_to have_content "Numismatic Accessions"
        expect(response.body).not_to have_content "123123123123123"
      end
    end
  end
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
