# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NumismaticIssuesController do
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
        metal: ["Bronze"],
        rights_statement: "Test Statement",
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        metal: ["Bronze"]
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_issue }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_issue }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_issue }
      let(:extra_params) { { numismatic_issue: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
  end
  describe "GET /concern/numismatic_issues/:id/manifest" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "returns a IIIF manifest for a resource with a file" do
      coin = FactoryBot.create_for_repository(:complete_open_coin, files: [file])
      numismatic_issue = FactoryBot.create_for_repository(:complete_open_numismatic_issue, member_ids: [coin.id])
      get :manifest, params: { id: numismatic_issue.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:manifests].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "multi-part"
    end
  end
end
