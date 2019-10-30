# frozen_string_literal: true
require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe NumismaticsImportService do
  with_queue_adapter :inline

  subject(:numismatics_import_service) do
    described_class.new(
      db_adapter: db_adapter,
      collection_id: collection_id,
      depositor: depositor,
      file_root: file_root,
      logger: logger
    )
  end
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:db_adapter) { instance_double(NumismaticsImportService::TinyTdsAdapter) }
  let(:collection_id) { collection.id }
  let(:depositor) { FactoryBot.create(:admin) }
  let(:file_root) { Rails.root.join("spec", "fixtures", "numismatics") }
  let(:logger) { Logger.new(IO::NULL) }

  describe "#ingest_issue" do
    let(:issue_number) { 1 }

    before do
      allow(db_adapter).to receive(:execute).and_return([{ "CoinID" => 1 }])
      numismatics_import_service.ingest_issue(issue_number: issue_number)
    end

    it "creates a new Issue with member Coins from each file", run_real_characterization: true, run_real_derivatives: true do
      expect(collection.decorate.members).not_to be_empty
      members = collection.decorate.members
      expect(members.length).to eq 2
      first_coin = members.find { |member| member.is_a?(Numismatics::Coin) }
      expect(first_coin.decorate.decorated_file_sets).not_to be_empty
      obverse_file_set = first_coin.decorate.decorated_file_sets.first
      expect(obverse_file_set.derivative_files).not_to be_empty
      reverse_file_set = first_coin.decorate.decorated_file_sets.last
      expect(reverse_file_set.derivative_files).not_to be_empty
    end

    it "filters for only image files in the TIFF and JPEG format, and selects TIFF file if both are available" do
      expect(collection.decorate.members).not_to be_empty
      members = collection.decorate.members
      first_coin = members.find { |member| member.is_a?(Numismatics::Coin) }
      expect(first_coin.decorate.decorated_file_sets).not_to be_empty
      file_sets = first_coin.decorate.decorated_file_sets
      expect(file_sets.length).to eq 2
      labels = file_sets.map(&:file_metadata).flatten.map(&:label).flatten
      expect(labels).to include "1R.jpg"
      expect(labels).to include "1O.tif"
      expect(labels).not_to include "1O.jpg"
    end
  end
end
