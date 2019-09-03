# frozen_string_literal: true
require "rails_helper"

RSpec.describe ExportCollectionPDFJob do
  describe ".perform" do
    let(:col) { FactoryBot.create_for_repository(:collection) }
    let(:pulfa_id) { "C0652_c0377" }
    let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: [pulfa_id], member_of_collection_ids: [col.id]) }
    let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: [], member_of_collection_ids: [col.id]) }
    let(:export_service) { class_double("ExportService").as_stubbed_const }

    before do
      allow(export_service).to receive(:export_pdf)
      stub_pulfa(pulfa_id: pulfa_id)
      resource1
      resource2
    end

    it "exports the objects with source_metadata_identifiers to disk" do
      described_class.perform_now(col.id, logger: Logger.new(nil))
      expect(export_service).to have_received(:export_pdf).exactly(1).times
      expect(export_service).to have_received(:export_pdf).with(kind_of(ScannedResource), filename: "c0377.pdf")
    end
  end
end
