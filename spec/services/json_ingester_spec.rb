# frozen_string_literal: true
require "rails_helper"

RSpec.describe JsonIngester do
  context "when given a JSON hash" do
    it "ingests records according to it" do
      collection = FactoryBot.create_for_repository(:collection)
      json_file = generate_fixture_json(collection: collection)
      ingester = described_class.new(json_path: json_file.path)
      allow(IngestFolderJob).to receive(:perform_now).and_call_original

      ingester.ingest!
      resources = ChangeSetPersister.default.query_service.find_all_of_model(model: ScannedResource)

      expect(resources.to_a.length).to eq 2
      resource1 = resources.find { |r| r.title.include?("Princeton Plasma Physics Laboratory Highlights for Fiscal Year 2007") }
      resource2 = resources.find { |r| r != resource1 }
      # Ingesting metadata, needs to be a simple resource.
      expect(ChangeSet.for(resource1)).to be_a SimpleChangeSet
      expect(resource1.member_of_collection_ids).to eq [collection.id]
      # Ensure an empty creator doesn't create blank creators.
      expect(resource1.creator).to eq []
      expect(resource2.creator).to eq ["M. Hughes", "R. Sheneman", "J. Levine"]
      expect(resource1.local_identifier).to eq ["07Highlights"]
      # Ensure files ingested.
      expect(resource1.member_ids.length).to eq 1
      # Ensure ingest is called synchronously - for some reason. Feedback?
      expect(IngestFolderJob).to have_received(:perform_now).exactly(2).times
    end
  end

  # Creates fixture JSON and puts it in a file.
  def generate_fixture_json(collection:)
    json = JSON.parse(File.read(Rails.root.join("spec", "fixtures", "json_ingest.json")), symbolize_names: true)
    json[:records][0][:path] = Rails.root.join("spec", "fixtures", "bulk_ingest", "123456", "vol1").to_s
    json[:records][1][:path] = Rails.root.join("spec", "fixtures", "bulk_ingest", "123456", "vol2").to_s
    json[:records][0][:member_of_collection_ids] = [collection.id.to_s]
    json[:records][1][:member_of_collection_ids] = [collection.id.to_s]
    file = Tempfile.new(["ingest_test", ".json"])
    file.puts(json.to_json)
    file.rewind
    file
  end
end
