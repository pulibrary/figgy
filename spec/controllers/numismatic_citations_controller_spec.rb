# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NumismaticCitationsController do
  with_queue_adapter :inline
  let(:user) { nil }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
  before do
    sign_in user if user
    reference
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
    let(:valid_params) do
      {
        numismatic_reference_id: reference.id,
        part: "chapter 1",
        number: "123"
      }
    end
    let(:invalid_params) do
      {
        numismatic_reference_id: nil,
        part: "chapter 1",
        number: "123"
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    context "adding to a parent coin" do
      let(:user) { FactoryBot.create(:admin) }
      let(:coin) { FactoryBot.create_for_repository(:coin) }

      it "adds the id to the coin's citation ids and redirects to parent coin" do
        post :create, params: { numismatic_citation: valid_params.merge(citation_parent_id: coin.id) }

        updated = Valkyrie.config.metadata_adapter.query_service.find_by(id: coin.id)
        expect(updated.numismatic_citation_ids).not_to be_empty
        expect(response).to redirect_to("http://test.host/catalog/#{coin.id}")
      end
    end
    context "adding to a parent numismatic issue" do
      let(:user) { FactoryBot.create(:admin) }
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }

      it "adds the id to the coin's citation ids and redirects to parent coin" do
        post :create, params: { numismatic_citation: valid_params.merge(citation_parent_id: issue.id) }

        updated = Valkyrie.config.metadata_adapter.query_service.find_by(id: issue.id)
        expect(updated.numismatic_citation_ids).not_to be_empty
        expect(response).to redirect_to("http://test.host/catalog/#{issue.id}")
      end
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_citation }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_citation }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_citation }
      let(:extra_params) { { numismatic_citation: { part: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
  end
end
