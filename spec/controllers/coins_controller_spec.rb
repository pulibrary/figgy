# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe CoinsController do
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
        size: [5],
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        size: [5]
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end

    context "creating a coin in the context of an issue" do
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }
      let(:user) { FactoryBot.create(:admin) }

      before do
        sign_in user
      end

      it "adds the coin as a member of the issue" do
        post :create, params: { coin: { append_id: issue.id.to_s, weight: 5 } }

        updated_issue = Valkyrie.config.metadata_adapter.query_service.find_by(id: issue.id)
        expect(updated_issue.member_ids).not_to be_empty
      end
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :coin }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :coin }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :coin }
      let(:extra_params) { { coin: { size: [6] } } }
      it_behaves_like "an access controlled update request"
    end
  end
end
