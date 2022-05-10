# frozen_string_literal: true
require "rails_helper"

RSpec.describe ResourcesController do
  with_queue_adapter :test

  describe "#refresh_remote_metadata" do
    with_queue_adapter :test

    let(:token) { AuthToken.create!(group: ["metadata_refresh"], label: "pulfalight-token") }

    context "with a list of archival_collection_codes" do
      it "starts a RefreshArchivalCollectionJob, returns 202" do
        body = { archival_collection_codes: ["C0140", "C0001"] }
        post "refresh_remote_metadata", params: { auth_token: token.token }, body: body.to_json

        expect(RefreshArchivalCollectionJob).to have_been_enqueued.twice
        expect(RefreshArchivalCollectionJob).to have_been_enqueued.with(collection_code: "C0140")
        expect(RefreshArchivalCollectionJob).to have_been_enqueued.with(collection_code: "C0001")
        expect(response).to have_http_status(:accepted)
      end
    end

    context "with an empty list" do
      it "returns 204" do
        body = { archival_collection_codes: [] }
        post "refresh_remote_metadata", params: { auth_token: token.token }, body: body.to_json

        expect(RefreshArchivalCollectionJob).not_to have_been_enqueued
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
