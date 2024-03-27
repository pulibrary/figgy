# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "has a health check" do
      stub_aspace_login
      allow(Net::SMTP).to receive(:new).and_return(instance_double(Net::SMTP, "open_timeout=": nil, start: true))

      get "/health.json"

      expect(response).to be_successful
    end

    it "errors when it can't contact the SMTP server" do
      get "/health.json?providers[]=smtpstatus"

      expect(response).not_to be_successful
    end

    it "errors when solr is down" do
      stub_aspace_login
      allow(Blacklight.default_index.connection).to receive(:uri).and_return(URI("http://example.com/bla"))
      stub_request(:get, "http://example.com/solr/admin/cores?action=STATUS").to_return(body: { responseHeader: { status: 500 } }.to_json, headers: { "Content-Type" => "text/json" })

      get "/health.json?providers[]=solrstatus"

      expect(response).not_to be_successful
      expect(response.status).to eq 503
      solr_response = JSON.parse(response.body)["results"].find { |x| x["name"] == "SolrStatus" }
      expect(solr_response["message"]).to start_with "The solr has an invalid status"
    end

    it "errors when rabbitmq is down", rabbit_stubbed: true do
      stub_aspace_login

      allow(Figgy.messaging_client).to receive(:bunny_client).and_raise(Bunny::TCPConnectionFailedForAllHosts, "Could not establish TCP connection to any of the configured hosts")

      get "/health.json"

      expect(response).not_to be_successful
      expect(response.status).to eq 503
      rabbit_response = JSON.parse(response.body)["results"].find { |x| x["name"] == "RabbitMqStatus" }
      expect(rabbit_response["message"]).not_to be_blank
    end
  end
end
