# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe CoinsController, type: :controller do
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
  describe "GET /concern/coins/:id/manifest" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "returns a IIIF manifest for a resource with a file" do
      coin = FactoryBot.create_for_repository(:complete_open_coin, files: [file])

      get :manifest, params: { id: coin.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "individuals"
    end
  end
end
