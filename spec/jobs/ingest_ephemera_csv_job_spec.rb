# frozen_string_literal: true

require "rails_helper"

RSpec.describe IngestEphemeraCSVJob do
  describe ".perform" do
    let(:service) { instance_double(IngestEphemeraCSV) }
    let(:record) { FactoryBot.build(:ephemera_folder) }
    before do
      allow(IngestEphemeraCSV).to receive(:new).and_return(service)
      allow(service).to receive(:ingest).and_return([record])
    end
    it "Ingests an ephemera CSV file" do
      described_class.perform_now("project_id", "mdata_table", "/path/to/files")
      expect(service).to have_received(:ingest)
    end
  end
end
