# frozen_string_literal: true
require "rails_helper"

RSpec.describe ExportCollectionPDFJob do
  describe ".perform" do
    let(:col) { FactoryBot.create_for_repository(:collection) }
    let(:pulfa_id) { "C0652_c0377" }
    let(:pulfa_id2) { "AC044_c0003" }
    let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: [pulfa_id], member_of_collection_ids: [col.id]) }
    let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: [], member_of_collection_ids: [col.id]) }
    let(:resource3) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: [pulfa_id2], member_of_collection_ids: [col.id], member_ids: [vol1.id, vol2.id]) }
    let(:vol1) { FactoryBot.create_for_repository(:scanned_resource, title: "Volume 1") }
    let(:vol2) { FactoryBot.create_for_repository(:scanned_resource, title: "Volume 2") }

    before do
      allow(ExportService).to receive(:export_resource_or_volumes_pdf).and_call_original
      allow(ExportService).to receive(:export_pdf)
      stub_findingaid(pulfa_id: pulfa_id)
      stub_findingaid(pulfa_id: pulfa_id2)
      resource1
      resource2
      resource3
    end

    it "exports scanned resources and multi-volume work volumes with source_metadata_identifiers to disk" do
      described_class.perform_now(col.id, logger: Logger.new(nil))
      expect(ExportService).to have_received(:export_pdf).with(kind_of(ScannedResource), filename: "c0377.pdf")
      expect(ExportService).to have_received(:export_pdf).with(kind_of(ScannedResource), filename: "c0003_0.pdf")
      expect(ExportService).to have_received(:export_pdf).with(kind_of(ScannedResource), filename: "c0003_1.pdf")
    end
  end
end
