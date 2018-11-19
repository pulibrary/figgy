# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NumismaticAccessionsController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
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
      let(:extra_params) { { numismatic_accession: { type: ["gift"] } } }
      it_behaves_like "an access controlled update request"
    end
  end
  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has lists all numismatic accessions" do
        FactoryBot.create_for_repository(:numismatic_accession, accession_number: 123)

        get :index
        expect(response.body).to have_content "123"
      end
    end
  end
end
