# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health Check", type: :request do
  before(:all) do
    # Setup ocr in path in tmp directory
    ocr_in_path = Figgy.config["ocr_in_path"]
    FileUtils.mkdir_p(ocr_in_path) unless File.directory?(ocr_in_path)
  end

  describe "GET /health" do
    it "has a health check" do
      stub_aspace_login

      get "/health.json"

      expect(response).to be_successful
    end

    it "errors when solr is down" do
      stub_aspace_login
      allow(Blacklight.default_index.connection).to receive(:uri).and_return(URI("http://example.com/bla"))
      stub_request(:get, "http://example.com/solr/admin/cores?action=STATUS").to_return(body: { responseHeader: { status: 500 } }.to_json, headers: { "Content-Type" => "text/json" })

      get "/health.json"

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

    context "when there are files in the ocr in directory" do
      after do
        # Cleanup files
        ocr_in_path = Figgy.config["ocr_in_path"]
        Dir["#{ocr_in_path}/*"].each { |f| File.delete(f) }
      end

      it "errors when there are pdfs in the ocr directory older than 12 hours" do
        stub_aspace_login
        thirteen_hours_ago = Time.current.to_time - 13.hours
        ocr_in_path = Figgy.config["ocr_in_path"]
        FileUtils.touch("#{ocr_in_path}/file1.pdf", mtime: thirteen_hours_ago)

        get "/health.json"

        expect(response).not_to be_successful
        expect(response.status).to eq 503
        file_watcher_response = JSON.parse(response.body)["results"].find { |x| x["name"] == "FileWatcherStatus" }
        expect(file_watcher_response["message"]).not_to be_blank
      end

      it "is successful when there are pdfs in the ocr directory younger than 12 hours" do
        stub_aspace_login
        ocr_in_path = Figgy.config["ocr_in_path"]
        FileUtils.touch("#{ocr_in_path}/file1.pdf")

        get "/health.json"

        expect(response).to be_successful
      end
    end
  end
end
