# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestMoscowMODSJob do
  describe ".perform" do
    let(:service) { instance_double(IngestEphemeraMODS::IngestMoscowMODS) }
    let(:record) { FactoryBot.build(:ephemera_folder) }
    before do
      allow(IngestEphemeraMODS::IngestMoscowMODS).to receive(:new).and_return(service)
      allow(service).to receive(:ingest).and_return(record)
    end
    it "Ingests an ephemera MODS file" do
      described_class.perform_now("project_id", "/path/to/mods", "/path/to/files")
      expect(service).to have_received(:ingest)
    end
  end
end
