# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health Monitor", type: :request do
  before(:all) do
    # Setup ocr in path in tmp directory
    ocr_in_path = Figgy.config["ocr_in_path"]
    FileUtils.mkdir_p(ocr_in_path) unless File.directory?(ocr_in_path)
  end

  describe "GET /health" do
    it "has a success response even if there are failures to non-critical services (e.g sidekiq)" do
      get "/health.json"

      expect(response).to be_successful
    end

    it "errors when there's a failure to a critical service" do
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:execute) do |instance|
        raise StandardError if database.blank? || instance.pool.db_config.name == database.to_s
      end

      get "/health.json"

      expect(response).not_to be_successful
      expect(response).to have_http_status :service_unavailable
    end

    it "errors when it can't contact the SMTP server" do
      get "/health.json?providers[]=smtpstatus"

      expect(response).not_to be_successful
    end

    it "errors when solr is down" do
      allow(Blacklight.default_index.connection).to receive(:uri).and_return(URI("http://example.com/bla"))
      stub_request(:get, "http://example.com/solr/admin/cores?action=STATUS").to_return(body: { responseHeader: { status: 500 } }.to_json, headers: { "Content-Type" => "text/json" })

      get "/health.json?providers[]=solrstatus"

      expect(response).not_to be_successful
      expect(response.status).to eq 503
      solr_response = JSON.parse(response.body)["results"].find { |x| x["name"] == "SolrStatus" }
      expect(solr_response["message"]).to start_with "The solr has an invalid status"
    end

    it "errors when rabbitmq is down", rabbit_stubbed: true do
      allow(Figgy.messaging_client).to receive(:bunny_client).and_raise(Bunny::TCPConnectionFailedForAllHosts, "Could not establish TCP connection to any of the configured hosts")

      get "/health.json?providers[]=rabbitmqstatus"

      expect(response).not_to be_successful
      expect(response.status).to eq 503
      rabbit_response = JSON.parse(response.body)["results"].find { |x| x["name"] == "RabbitMqStatus" }
      expect(rabbit_response["message"]).not_to be_blank
    end

    it "is configured to monitor all desired Sidekiq queues" do
      sidekiq_configuration = HealthMonitor.configuration.providers.find { |provider| provider.name == "Sidekiq" }.configuration

      # test that all the queues are checked, and the configuration of each
      expect(sidekiq_configuration.queues).to match(
        "high" => hash_including(latency: 5.days, queue_size: 1_000_000),
        "mailers" => hash_including(latency: 5.days, queue_size: 1_000_000),
        "default" => hash_including(latency: 5.days, queue_size: 1_000_000),
        "low" => hash_including(latency: 5.days, queue_size: 1_000_000),
        "super_low" => hash_including(latency: 5.days, queue_size: 1_000_000),
        "realtime" => hash_including(latency: 30.seconds, queue_size: 100)
      )
      expect(sidekiq_configuration.maximum_amount_of_retries).to match(17)
    end

    context "when there are files in the ocr in directory" do
      before do
        allow(Net::SMTP).to receive(:new).and_return(instance_double(Net::SMTP, "open_timeout=": nil, start: true))
      end

      after do
        # Cleanup files
        ocr_in_path = Figgy.config["ocr_in_path"]
        Dir["#{ocr_in_path}/*"].each { |f| File.delete(f) }
      end

      it "errors when there are pdfs in the ocr directory older than 12 hours" do
        thirteen_hours_ago = Time.current.to_time - 13.hours
        ocr_in_path = Figgy.config["ocr_in_path"]
        FileUtils.touch("#{ocr_in_path}/12345.pdf", mtime: thirteen_hours_ago)

        get "/health.json?providers[]=filewatcherstatus"

        expect(response).not_to be_successful
        expect(response.status).to eq 503
        file_watcher_response = JSON.parse(response.body)["results"].find { |x| x["name"] == "FileWatcherStatus" }
        expect(file_watcher_response["message"]).not_to be_blank
      end

      it "is successful when there are pdfs in the ocr directory younger than 12 hours" do
        ocr_in_path = Figgy.config["ocr_in_path"]
        FileUtils.touch("#{ocr_in_path}/12345.pdf")

        get "/health.json?providers[]=filewatcherstatus"

        expect(response).to be_successful
      end

      it "is successful when there are pdfs with non-digit titles in the ocr directory older than 12 hours" do
        thirteen_hours_ago = Time.current.to_time - 13.hours
        ocr_in_path = Figgy.config["ocr_in_path"]
        FileUtils.touch("#{ocr_in_path}/file1.pdf", mtime: thirteen_hours_ago)

        get "/health.json?providers[]=filewatcherstatus"

        expect(response).to be_successful
      end
    end

    context "when checking the status of the mounted directory" do
      it "errors when the mount directory is empty" do
        config_mock = Figgy.config.merge(
          { "ingest_folder_path" => Rails.root.join("spec", "fixtures", "fake_directory").to_s }
        )
        allow(Figgy).to receive(:config).and_return(config_mock)

        get "/health.json?providers[]=ingestmountstatus"

        expect(response).not_to be_successful
      end

      it "succeeds when the mount directory has contents" do
        get "/health.json?providers[]=ingestmountstatus"

        expect(response).to be_successful
      end
    end
  end
end
