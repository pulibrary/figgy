# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "has a health check" do
      stub_aspace_login
      get "/health.json"
      expect(response).to be_successful
    end

    it "errors when a service is down" do
      stub_aspace_login
      allow(Blacklight.default_index.connection).to receive(:uri).and_return(URI("http://example.com/bla"))
      stub_request(:get, "http://example.com/solr/admin/cores?action=STATUS").to_return(body: { responseHeader: { status: 500 } }.to_json, headers: { "Content-Type" => "text/json" })

      get "/health.json"

      expect(response).not_to be_successful
      expect(response.status).to eq 503
      solr_response = JSON.parse(response.body)["results"].find { |x| x["name"] == "SolrStatus" }
      expect(solr_response["message"]).to start_with "The solr has an invalid status"
    end
  end
end
